# ZhenyaManagerPool - Независимое управление жизненным циклом менеджеров рекламы

## Проблема

При использовании стратегии 1 (Zhenya) менеджер рекламы (`ZhenyaAdManager`) должен продолжать работу даже после того, как объект `Interstitial` был освобожден из памяти. Это необходимо для завершения:
- Текущих аукционов
- Загрузки рекламы
- Рефиллов кэша
- Показа рекламы

## Решение

Создан синглтон `ZhenyaManagerPool`, который:

1. **Хранит менеджеры независимо от Interstitial объектов**
   - Менеджеры живут в пуле и не удаляются при деаллокации Interstitial
   - Один менеджер на `auctionKey`

2. **Управляет повторным использованием**
   - Если создается новый Interstitial с тем же `auctionKey`, он получает доступ к существующему менеджеру
   - Сохраняется состояние кэша и текущие операции

3. **Автоматически очищает неиспользуемые менеджеры**
   - Каждые 60 секунд запускается проверка
   - Удаляются менеджеры в состоянии `.idle` старше 5 минут, у которых нет активного Interstitial

4. **Потокобезопасен**
   - Все операции синхронизированы через `DispatchQueue` с барьерами

## Архитектура

```
┌─────────────────┐
│  Interstitial   │ (может быть деаллоцирован)
└────────┬────────┘
         │ weak reference
         ▼
┌─────────────────────────┐
│  ZhenyaManagerPool      │ (синглтон)
│  ┌──────────────────┐   │
│  │ managers: [      │   │
│  │   "key1": Entry, │   │
│  │   "key2": Entry  │   │
│  │ ]                │   │
│  └──────────────────┘   │
└────────┬────────────────┘
         │ strong reference
         ▼
┌─────────────────────────┐
│   ZhenyaAdManager       │ (продолжает работу)
│   - loadAd()            │
│   - performAuction()    │
│   - cache refill        │
└─────────────────────────┘
```

## Использование

### В Interstitial.swift

```swift
private var currentManager: Manager {
    if strategy == 1 {
        // Для Zhenya стратегии используем пул
        return ZhenyaManagerPool.shared.getOrCreateManager(
            for: auctionKey,
            interstitial: self,
            delegate: self
        ) as Manager
    } else {
        // Для других стратегий используем локальный менеджер
        // ...
    }
}
```

### Сценарии работы

#### Сценарий 1: Нормальный lifecycle
```swift
let interstitial = Interstitial(auctionKey: "main")
interstitial.loadAd()
// ... менеджер загружает рекламу
interstitial.showAd(from: viewController)
// ... реклама показывается
// interstitial деаллоцируется
// ✅ Менеджер продолжает рефилл кэша
```

#### Сценарий 2: Создание нового Interstitial с тем же ключом
```swift
let interstitial1 = Interstitial(auctionKey: "main")
interstitial1.loadAd()
// interstitial1 деаллоцируется

let interstitial2 = Interstitial(auctionKey: "main")
// ✅ interstitial2 получает доступ к тому же менеджеру
// ✅ Кэш и состояние сохранены
```

#### Сценарий 3: Разные ключи
```swift
let interstitial1 = Interstitial(auctionKey: "screen1")
let interstitial2 = Interstitial(auctionKey: "screen2")
// ✅ Создаются два независимых менеджера
// ✅ Каждый со своим кэшем и состоянием
```

## Очистка

Менеджеры автоматически удаляются из пула когда:
1. Они в состоянии `.idle` 
2. Прошло более 5 минут с создания
3. Нет активного Interstitial объекта (weak reference == nil)

Также можно принудительно удалить менеджер:
```swift
ZhenyaManagerPool.shared.removeManager(for: auctionKey)
```

## Преимущества

✅ **Надежность** - операции завершаются даже если UI контроллер закрыт  
✅ **Эффективность** - повторное использование менеджеров и кэша  
✅ **Чистота памяти** - автоматическая очистка неиспользуемых менеджеров  
✅ **Потокобезопасность** - concurrent queue с барьерами  
✅ **Прозрачность** - не требует изменений в API Interstitial
