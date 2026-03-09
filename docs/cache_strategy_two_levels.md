# CacheStrategy 3 — Two-Level Cache

## Проблема

| Strategy 1 (Zhenya) | Strategy 2 (Dima) |
|---|---|
| Быстрый callback — первый bid отдаётся немедленно | Fallback — используется если аукцион провалился |
| Нет TTL/reservation → нет защиты от двойного показа | Нет instant-serve → всегда ждёт полный аукцион |
| Нет consent-фильтрации | Медленнее ощутимо при повторных loadAd() |

**Цель:** объединить оба подхода, сохранив сильные стороны каждого.

---

## Архитектура: два уровня кэша

```
┌─────────────────────────────────────────────────────────────────┐
│                          loadAd()                               │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │   L1 Cache peek()   │  ← CacheStorage (Zhenya)
                    │   sticky + price    │    sorted by price DESC
                    └──────────┬──────────┘
                               │
              ┌────────────────┴────────────────┐
              │ HIT                             │ MISS
              ▼                                 ▼
    Serve immediately                    Run Auction
    (no auction needed)          (ZhenyaAuctionController)
                                         │
                          ┌──────────────┴───────────────┐
                          │ singleLoadCompletion (per bid)│
                          └──────────────┬───────────────┘
                                         │
                            ┌────────────▼────────────┐
                            │ L1 insert (first=sticky) │
                            │ first bid → didLoad()    │
                            │ rest → cache silently    │
                            └────────────┬────────────┘
                                         │
                          ┌──────────────▼───────────────┐
                          │   Auction finishes           │
                          └──────────────┬───────────────┘
                                         │
                  ┌──────────────────────┴────────────────────┐
                  │ has bids                                   │ no bids
                  ▼                                            ▼
        Cache runner-ups → L2                      L2 fallback lookup
        (BidCacheStore, TTL+reserve)               (BidCacheStore)
                                                        │
                                          ┌─────────────┴──────────────┐
                                          │ HIT                        │ MISS
                                          ▼                            ▼
                                   reserve() → show           didFailToLoad()
```

---

## Уровни кэша

### L1 — Fast Cache (Zhenya's CacheStorage)

**Назначение:** instant-serve, первичный путь

| Свойство | Значение |
|---|---|
| Тип данных | `CacheStorage.Item` (готовый Ad + ImpressionController) |
| Вставка | Per-bid, через `singleLoadCompletion` |
| Извлечение | `popFirst()` при `show()` |
| Sticky | Первый bid блокируется на позиции 0 |
| Ценовой порог | 50% от max цены в текущей итерации |
| Вытеснение | Cheapest-out (сортировка по цене DESC) |
| TTL | Нет (price-based eviction) |
| Consent | Нет |

```
L1 после аукциона: [$5.00*] [$3.50] [$2.10]   (* = sticky)
show() → pop $5.00 → L1: [$3.50] [$2.10]
loadAd() → peek $3.50 → отдаём мгновенно
```

### L2 — Fallback Cache (Dima's BidCacheStore)

**Назначение:** защита от no-fill, вторичный путь

| Свойство | Значение |
|---|---|
| Тип данных | `CachedBid` (lazy builders, TTL) |
| Вставка | Runner-ups после успешного аукциона |
| Извлечение | `reserve()` → `confirm()`/`release()` |
| Reservation timeout | 40 сек |
| TTL | 8 мин (banner), 10 мин (interstitial) |
| Price threshold | policy: min healthy TTL, price sort |

```
L2 после аукциона (runner-ups): [Bid B $3.50, TTL=10min] [Bid C $2.10]
Следующий аукцион → no fill → L2 fallback → reserve(Bid B) → show
show() succeed → confirm(Bid B) → permanent remove
show() fail    → release(Bid B) → return to pool
```

#### git ption — зачем нужна и как работает

Без резервации возможен **двойной показ**: выбрали bid для показа → до вызова `show()` пришёл ещё один `loadAd()` → тот же bid выбирается снова → одно объявление показывается дважды.

```
reserve(entryID)
  → bid перемещается: entries → reserved (недоступен для peek/reserve)
  → reservedAt = now
  → expiresAt  = now + 40 сек          ← reservationTimeout

Исход A: show() успешен
  → willPresent() → confirm() → bid удалён навсегда

Исход B: show() не случился (ошибка или закрыли до показа)
  → didFailToPresent() / didHide() → release() → bid возвращается в entries

Исход C: ad истёк до показа
  → didExpire() → release() → bid возвращается в entries (если TTL ещё не вышел)

Исход D: 40 сек прошло, ни confirm ни release не пришли
  → maintenance() при следующем вызове:
      bid ещё живой по TTL  → возвращается в entries автоматически
      bid истёк по TTL      → выбрасывается
```

**Почему 40 сек:** покрывает время между выбором бида и стартом показа — создание ImpressionController, анимация перехода, загрузка WebView. Если за 40 сек показ не начался — что-то пошло не так, bid безопасно возвращается в пул.

---

## Данные и жизненный цикл

### Unified Ad Manager

```
MergedInterstitialAdManager / MergedBannerAdManager
│
├── l1Cache: CacheStorage          ← from Zhenya
├── l2Cache: BidCacheStore         ← from Dima
├── cachePolicy: DCachePolicy      ← from Dima
└── auctionController: ZhenyaAuctionController  ← with singleLoadCompletion
```

### loadAd() — полный алгоритм

```
1. l1Cache.beginIteration()       ← сбросить ценовой трекер
2. L1 peek() → bid с ценой >= pricefloor?
   → да: state = .ready, didLoad()  [FAST PATH, нет аукциона]

3. Нет → createAuction()
   auction.singleLoadCompletion = { bid in
       inserted = l1Cache.insert(bid, sticky: isFirstBid)
       if inserted && isFirstBid:
           state = .ready
           didLoad()              [FAST PATH, первый bid аукциона]
       isFirstBid = false
   }

4. auction.load { result in
       switch result:
       case .success(bids):
           runner-ups → l2Cache (через cachePolicy)
       case .failure:
           if isFirstBid:         // ни один bid не пришёл
               tryL2Fallback()
   }
```

### show() — два источника

```
show()
  ├─► L1 pop → ImpressionController готов (объект уже создан)
  │     → show immediately
  │
  └─► L2 reserved bid → CacheImpressionDelegateProxy
        ├─► willPresent()       → l2Cache.confirm()
        ├─► didFailToPresent()  → l2Cache.release()
        └─► didHide()           → l2Cache.release()
```

---

## Компоненты и что переиспользуется

```
┌─────────────────────────────────────────────────────────────┐
│  NEW: MergedSandbox/                                        │
│  ├── MergedBannerAdManager.swift     ← новый               │
│  ├── MergedInterstitialAdManager.swift ← новый             │
│  └── MergedSandbox.swift             ← wiring              │
└─────────────────────────────────────────────────────────────┘
         │ uses                    │ uses
         ▼                         ▼
┌─────────────────┐    ┌──────────────────────────────┐
│  Zhenya (reuse) │    │  Dima (reuse)                │
│  CacheStorage   │    │  BidCacheStore               │
│  BannerCache    │    │  CachedBid                   │
│  Storage        │    │  DCachePolicy                │
│  Zhenya         │    │  BannerCachePolicy           │
│  AuctionCtrl    │    │  InterstitialCachePolicy     │
│  ManagerPool    │    │  CacheImpressionProxy        │
└─────────────────┘    │  CacheStatsTracker           │
                       └──────────────────────────────┘
```

**Удаляется после миграции:** отдельные `ZhenyaSandbox/` и `DimaSandbox/` ad managers (оба sandbox остаются как библиотека компонентов до конца миграции).

---

## Итеративный план

### Шаг 1 — Manager skeleton _(новый файл, нет изменений в существующем)_

Создать `MergedInterstitialAdManager` с заглушками:
- `loadAd()` с L1 peek + auction запуском
- `show()` с L1 pop
- Без L2 (пока)

**Критерий готовности:** работает как Zhenya (L1 only), проходит существующие тесты.

---

### Шаг 2 — Подключить L2 после аукциона _(изменения только в новом файле)_

В обработчике `auction.load` completion:
- Success → `cachePolicy.selectRunnerUps()` → `l2Cache.replace()`
- Failure + `isFirstBid` (ни один bid не пришёл) → `tryL2Fallback()`

**Критерий готовности:** при провале аукциона — показываем из L2 если есть.

---

### Шаг 3 — Banner manager _(аналогично шагу 1-2)_

`MergedBannerAdManager` по той же схеме.
Banner specifics: `prepareForReuse()` делает `l1Cache.pop()` + L2 использует `BannerCachePolicy`.

---

### Шаг 4 — Manager Pool _(порт ZhenyaManagerPool)_

Чтобы L1 кэш выживал при пересоздании рекламного объекта (например, при смене экрана):
- Порт `ZhenyaManagerPool` для `MergedInterstitialAdManager`
- Ключ: `auctionKey` (placement)
- Автоочистка: 5 мин idle + нет живого рекламного объекта

---

### Шаг 5 — AdCacheConfig: добавить strategy = 3

```swift
// AdCacheConfig.swift
// strategy: 0=default, 1=Zhenya, 2=Dima, 3=Merged
```

Точки подключения: `BannerView.swift`, `Interstitial.swift` — добавить `case 3`.

---

### Шаг 6 — QA + Cleanup

- A/B тест strategy 3 против 1 и 2
- После подтверждения: удалить `ZhenyaSandbox/` и `DimaSandbox/` managers (оставить только shared компоненты)
- Переименовать `MergedSandbox/` → финальное имя

---

## Оценка сложности

| Шаг | Новые файлы | Изменения в существующих | Риск |
|---|---|---|---|
| 1 — Manager skeleton | 2 | 0 | низкий |
| 2 — L2 подключение | 0 | 2 (новые файлы из шага 1) | низкий |
| 3 — Banner | 1 | 0 | низкий |
| 4 — Manager Pool | 1 | 2 | средний |
| 5 — Config wiring | 0 | 2 | низкий |
| 6 — Cleanup | удаление | 2 | низкий |

Шаги 1–3 — независимы от существующего кода, новые файлы.
Самая рискованная часть — шаг 4 (Manager Pool), но это порт готового кода из Zhenya.

**Общий объём:** ~400–500 строк нового кода + удаление ~600 строк после cleanup.
