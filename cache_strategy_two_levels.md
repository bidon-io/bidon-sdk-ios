# CacheStrategy 3 — Two-Level Cache

## Cache config

Cache size - размер Main кэша
Fallback cache size - размер Fallback кэша
Treshold - трешхолд
TTL - TTL :)

## AdManager

AdManager.load(pricefloor)
Если в Main Cache есть реклама, ecpm которой >= pricefloor, вызываем onLoad callback
Если Main Cache пустой или нет рекламы, ecpm которой >= pricefloor, запускаем аукцион
Если аукцион завершается успешно, мы отдаем в onLoad коллбэке первый бид, даже если он не самый дорогой
Если аукцион завершается с ошибкой (например, no fill), берем самый дорогой ад юнит из Fallback Cache

Диаграмма класса
AdManager
------------------
-auction - ссылка на объект, который проводит ауцион
-load
-show - для фулскринов

## Аукцион

Опрашиваются все ад юниты по очереди
Пример водопада: [10$, 8$, 7$, 6$, 5$, 4$, 3$, 2$, 1$]
Как только зафилил первый ад юнит, например, за 8$, вызываем onLoad коллбэк, далее опрашиваем все ад юниты
Если ад юнит филит с ценой >= `first fill ecpm * treshold`, вызываем MainCache.insert(), если меньше, то вызываем FallbackCache.insert()  

Диаграмма класса
AuctionController
------------------
-loadWithCompletion - запускает аукцион, после опроса всего водопада вызывается completion
-singleLoadCompletion - вызывается каждый раз, когда зафилил какой-то ад юнит. Если он вызвался первый раз за цикл опроса, то вызываем onLoad

---

## Main Cache

По сути это массив, в котором есть sticky голова, которая не участвует в сортировке. Все остальные элементы всегда сортируются

CacheStorage
---------------
-init(capacity) - ининицализируется с размером cacheSize
-insert(element, isSticky) - пытается вставить элемент
-pop - возвращает элемент и его удаляет
-peek - возврвщает элемент без удаления

## Fallback Cache

FallbackCacheStorage
---------------
-init(capacity) - ининицализируется с размером Fallback cache size
-insert(element) - пытается вставить элемент
-pop - возвращает элемент и его удаляет
-peek - возврвщает элемент без удаления

### insert логика:
1. **Double check**: элемент с таким же id уже в кеше?
   - Цена совпадает → обновить на месте, SUCCESS
   - Цена отличается → удалить старый, продолжить как новый элемент
2. Кеш полон → если новый дороже самого дешёвого, вытеснить его; иначе REJECTED
3. Вставить, пересортировать по цене ↓

## Double check

**Double check** = совпадение `id` и `price` элемента с уже существующим в кеше.

Применяется в обоих кешах (Main и Fallback) при `insert`:
- **id совпал + цена совпала** → это тот же ад юнит с той же ценой. Обновляем на месте (по сути no-op). Не дублируем между кешами.
- **id совпал + цена отличается** → это новый бид от той же сетки. Удаляем старый, вставляем новый как обычный элемент (проходит все проверки: threshold, capacity и т.д.)
- **id не совпал** → обычная вставка нового элемента

---

## Схема работы

```
AdManager.load(pricefloor)
  │
  ├─ Main Cache.peek()
  │     │
  │     ├─ есть элемент и ecpm >= pricefloor?
  │     │     → onLoad(cached element)
  │     │     → КОНЕЦ
  │     │
  │     └─ пусто или ecpm < pricefloor
  │           │
  │           ▼
  │     Запуск аукциона
  │     Водопад: [10$, 8$, 7$, 6$, 5$, ...]
  │           │
  │           │  Опрос ад юнитов по очереди
  │           │
  │           ├─ Первый fill (например 8$)
  │           │     ├─ Main Cache.insert(sticky: true)
  │           │     ├─ onLoad(bid)  ← отдаём сразу, не ждём остальных
  │           │     └─ firstFillEcpm = 8$
  │           │
  │           │  Продолжаем опрос остальных ад юнитов...
  │           │
  │           ├─ Следующий fill (ecpm >= firstFillEcpm * threshold)?
  │           │     │
  │           │     ├─ ДА (например 7$ при threshold 0.8, min = 6.4$)
  │           │     │     → Main Cache.insert(sticky: false)
  │           │     │
  │           │     └─ НЕТ (например 3$, ниже порога)
  │           │           → Fallback Cache.insert()
  │           │
  │           │  ... повторяем для каждого fill ...
  │           │
  │           └─ Водопад пройден → completion
  │
  │
  └─ Аукцион завершился с ошибкой (no fill)?
        │
        ├─ Fallback Cache.peek()
        │     │
        │     ├─ есть элемент?
        │     │     → onLoad(fallback element)
        │     │
        │     └─ пусто
        │           → onError(no fill)
        │
        ▼

AdManager.show()
  │
  ├─ Main Cache.pop() → показать рекламу
  │
  ▼

  Состояние после show:
  ┌──────────────────────────────────────────────┐
  │ Main Cache:     [sorted by price ↓] ...      │
  │                  (sticky снят после pop)      │
  │                                               │
  │ Fallback Cache: [sorted by price ↓] ...      │
  │                  (дешёвые биды, резерв)        │
  └──────────────────────────────────────────────┘
```

---

## Схема работы CacheStorage.insert(element, sticky)

```
insert(element, sticky)
  │
  │  ┌─────────────────────────────────────┐
  │  │ Структура кеша:                     │
  │  │                                     │
  │  │ Sticky mode:                        │
  │  │   [0: LOCKED] [1..N: sorted ↓]     │
  │  │                                     │
  │  │ Normal mode:                        │
  │  │   [0..N: sorted by price ↓]        │
  │  └─────────────────────────────────────┘
  │
  ├─ 1. Ценовой порог итерации (только при capacity > 1)
  │     │
  │     │  iterationMaxPrice — максимальная цена в текущей итерации,
  │     │  сбрасывается при beginIteration()
  │     │
  │     ├─ price > iterationMaxPrice?
  │     │     → обновить iterationMaxPrice = price
  │     │     → пропустить дальше
  │     │
  │     ├─ price >= iterationMaxPrice * 0.5?
  │     │     → пропустить дальше
  │     │
  │     └─ price < iterationMaxPrice * 0.5?
  │           → REJECTED (iterationThreshold)
  │
  ├─ 2. Double check: элемент с таким же id уже в кеше?
  │     │
  │     ├─ ДА, и цена совпадает (double check passed):
  │     │     → обновить на месте
  │     │     ├─ если sticky head активен и элемент на позиции 0 и вставка не sticky
  │     │     │     → REJECTED (stickyHeadProtected)
  │     │     ├─ если sticky и не на позиции 0 → поднять в голову
  │     │     ├─ пересортировать
  │     │     ├─ обрезать если > capacity
  │     │     └─ SUCCESS
  │     │
  │     └─ ДА, но цена отличается:
  │           → удалить старый элемент из кеша
  │           → если удалённый был sticky head → снять sticky mode
  │           → продолжить как новую вставку (шаги 3-6)
  │
  ├─ 3. Особый случай: capacity == 1 и sticky head активен и вставка не sticky
  │     │
  │     └─ REJECTED (stickyHeadProtected) — независимо от цены
  │           sticky head в рамках итерации не вытесняется
  │
  ├─ 4. Кеш полон?
  │     │
  │     │  Определить cheapest:
  │     │    sticky mode → самый дешёвый из хвоста (items[1..N])
  │     │    normal mode → последний элемент
  │     │
  │     ├─ новый дороже cheapest?
  │     │     → продолжить (cheapest будет вытеснен на шаге trim)
  │     │
  │     └─ новый дешевле или равен cheapest?
  │           → REJECTED (cacheFull)
  │
  ├─ 5. Кеш пуст?
  │     │
  │     └─ ДА: добавить элемент
  │           ├─ если sticky → включить sticky mode
  │           └─ SUCCESS
  │
  └─ 6. Вставка в непустой кеш
        │
        ├─ sticky?
        │     → вставить на позицию 0
        │     → включить sticky mode
        │
        └─ не sticky?
              → добавить в конец
        │
        ├─ пересортировать (голову не трогаем в sticky mode)
        ├─ обрезать хвост если count > capacity (trim)
        │     sticky mode → удаляем самый дешёвый из хвоста
        │     normal mode → удаляем последний
        └─ SUCCESS
```

### pop()

```
pop()
  │
  ├─ кеш пуст? → nil
  │
  └─ удалить items[0]
        │
        ├─ sticky mode был активен?
        │     → выключить sticky mode
        │     → пересортировать весь массив по цене ↓
        │
        └─ вернуть удалённый элемент
```

### peek()

```
peek()
  │
  └─ вернуть items[0] без удаления (или nil если пуст)
```

### beginIteration()

```
beginIteration()
  │
  └─ сбросить iterationMaxPrice = nil
     (следующий insert начнёт отсчёт порога заново)
```

