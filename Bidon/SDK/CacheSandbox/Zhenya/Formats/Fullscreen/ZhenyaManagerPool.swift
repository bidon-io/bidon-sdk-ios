//
//  ZhenyaManagerPool.swift
//  Bidon
//

import Foundation
import UIKit

/// Синглтон для управления ZhenyaAdManager независимо от жизненного цикла Interstitial
/// 
/// Этот класс решает проблему преждевременной деаллокации менеджеров рекламы для стратегии 1 (Zhenya).
/// Когда Interstitial объект освобождается из памяти, ZhenyaAdManager продолжает работу
/// (загрузка, аукцион, показ) до полного завершения всех операций.
///
/// Особенности:
/// - Один менеджер на auctionKey - если создается новый Interstitial с тем же auctionKey, 
///   он получит доступ к существующему менеджеру
/// - Автоматическая очистка - менеджеры в состоянии .idle удаляются через 5 минут
/// - Потокобезопасность - все операции синхронизированы через concurrent queue с барьерами
final class ZhenyaManagerPool {
    static let shared = ZhenyaManagerPool()
    
    private var managers: [String: ManagerEntry] = [:]
    private let queue = DispatchQueue(label: "com.bidon.zhenyapool", attributes: .concurrent)
    
    private struct ManagerEntry {
        weak var interstitial: Interstitial?
        let manager: ZhenyaAdManager<
            InterstitialAdTypeContext,
            InterstitialConcurrentAuctionControllerBuilder,
            InterstitialImpressionController,
            InterstitialAdaptersFetcher
        >
        let createdAt: Date
    }
    
    private init() {
        // Периодическая очистка менеджеров, которые больше не нужны
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.cleanupStaleManagers()
        }
    }
    
    /// Получить или создать менеджер для данного auctionKey
    func getOrCreateManager(
        for auctionKey: String?,
        interstitial: Interstitial,
        delegate: FullscreenAdManagerDelegate?
    ) -> ZhenyaAdManager<
        InterstitialAdTypeContext,
        InterstitialConcurrentAuctionControllerBuilder,
        InterstitialImpressionController,
        InterstitialAdaptersFetcher
    > {
        let key = auctionKey ?? "default"
        
        var result: ZhenyaAdManager<
            InterstitialAdTypeContext,
            InterstitialConcurrentAuctionControllerBuilder,
            InterstitialImpressionController,
            InterstitialAdaptersFetcher
        >!
        
        queue.sync(flags: .barrier) {
            if let entry = managers[key] {
                // Менеджер существует - ВСЕГДА обновляем delegate
                // потому что старый Interstitial мог быть освобождён (weak reference)
                let oldDelegate = entry.manager.delegate
                entry.manager.delegate = delegate
                
                Logger.debug("[ZhenyaCache] Reuse manager for key: \(key)")
                
                managers[key] = ManagerEntry(
                    interstitial: interstitial,
                    manager: entry.manager,
                    createdAt: entry.createdAt
                )
                result = entry.manager
            } else {
                // Создаем новый менеджер
                Logger.debug("[ZhenyaCache] New manager for key: \(key)")
                
                let manager = ZhenyaAdManager<
                    InterstitialAdTypeContext,
                    InterstitialConcurrentAuctionControllerBuilder,
                    InterstitialImpressionController,
                    InterstitialAdaptersFetcher
                >(
                    context: InterstitialAdTypeContext(),
                    delegate: delegate
                )
                
                let entry = ManagerEntry(
                    interstitial: interstitial,
                    manager: manager,
                    createdAt: Date()
                )
                
                managers[key] = entry
                result = manager
            }
        }
        
        return result
    }
    
    /// Получить существующий менеджер без создания нового
    func getManager(for auctionKey: String?) -> ZhenyaAdManager<
        InterstitialAdTypeContext,
        InterstitialConcurrentAuctionControllerBuilder,
        InterstitialImpressionController,
        InterstitialAdaptersFetcher
    >? {
        let key = auctionKey ?? "default"
        
        return queue.sync {
            return managers[key]?.manager
        }
    }
    
    /// Очистка менеджеров, которые завершили работу
    private func cleanupStaleManagers() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let now = Date()
            
            // Удаляем менеджеры, которые:
            // 1. В состоянии idle более 5 минут
            // 2. Их interstitial объект освобожден из памяти
            self.managers = self.managers.filter { (key, entry) in
                let isActive: Bool
                if case .idle = entry.manager.state {
                    isActive = false
                } else {
                    isActive = true
                }
                
                let isRecent = now.timeIntervalSince(entry.createdAt) < 300 // 5 минут
                let hasInterstitial = entry.interstitial != nil
                
                let shouldKeep = isActive || (isRecent && hasInterstitial)
                
                if !shouldKeep {
                    Logger.debug("[ZhenyaCache] Cleanup manager for key: \(key)")
                }
                
                // Оставляем менеджер если он активен ИЛИ (недавно создан И имеет interstitial)
                return shouldKeep
            }
        }
    }
    
    /// Принудительная очистка менеджера
    func removeManager(for auctionKey: String?) {
        let key = auctionKey ?? "default"
        
        queue.async(flags: .barrier) { [weak self] in
            self?.managers.removeValue(forKey: key)
        }
    }
}
