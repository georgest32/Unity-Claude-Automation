//
//  ExponentialBackoffManager.swift
//  AgentDashboard
//
//  Created on 2025-09-01
//  Advanced reconnection with exponential backoff, jitter, and circuit breaker pattern
//

import Foundation

// MARK: - Exponential Backoff Protocol

protocol ExponentialBackoffProtocol {
    func calculateDelay(for attempt: Int) -> TimeInterval
    func reset()
    var currentAttempt: Int { get }
    var nextDelay: TimeInterval { get }
}

// MARK: - Backoff Strategy

enum BackoffStrategy {
    case exponential(base: TimeInterval, multiplier: Double, maxDelay: TimeInterval)
    case fibonacci(base: TimeInterval, maxDelay: TimeInterval)
    case linear(interval: TimeInterval, maxDelay: TimeInterval)
    
    var name: String {
        switch self {
        case .exponential: return "exponential"
        case .fibonacci: return "fibonacci"
        case .linear: return "linear"
        }
    }
}

// MARK: - Jitter Strategy

enum JitterStrategy {
    case none
    case full        // Random 0 to computed_delay
    case equal       // computed_delay/2 + random(0, computed_delay/2)
    case decorrelated // Increases max jitter based on last random value
    
    func applyJitter(to delay: TimeInterval, lastDelay: TimeInterval = 0) -> TimeInterval {
        switch self {
        case .none:
            return delay
        case .full:
            return Double.random(in: 0...delay)
        case .equal:
            let half = delay / 2
            return half + Double.random(in: 0...half)
        case .decorrelated:
            let base = delay * 3
            let randomValue = Double.random(in: delay...base)
            return min(randomValue, delay * 2) // Cap to prevent excessive delays
        }
    }
}

// MARK: - Exponential Backoff Manager

final class ExponentialBackoffManager: ExponentialBackoffProtocol {
    
    // Configuration
    private let strategy: BackoffStrategy
    private let jitterStrategy: JitterStrategy
    private let maxAttempts: Int
    
    // State
    private var _currentAttempt: Int = 0
    private var lastDelay: TimeInterval = 0
    private var backoffMetrics = BackoffMetrics()
    
    // Fibonacci sequence cache
    private var fibonacciCache: [Int: TimeInterval] = [0: 1, 1: 1]
    
    init(strategy: BackoffStrategy = .exponential(base: 1.0, multiplier: 2.0, maxDelay: 60.0),
         jitterStrategy: JitterStrategy = .full,
         maxAttempts: Int = 15) {
        self.strategy = strategy
        self.jitterStrategy = jitterStrategy
        self.maxAttempts = maxAttempts
        
        print("[ExponentialBackoffManager] Initialized with strategy: \(strategy.name), jitter: \(jitterStrategy), max attempts: \(maxAttempts)")
    }
    
    var currentAttempt: Int {
        return _currentAttempt
    }
    
    var nextDelay: TimeInterval {
        return calculateDelay(for: _currentAttempt + 1)
    }
    
    func calculateDelay(for attempt: Int) -> TimeInterval {
        guard attempt > 0 else { return 0 }
        
        let rawDelay = calculateRawDelay(for: attempt)
        let jitteredDelay = jitterStrategy.applyJitter(to: rawDelay, lastDelay: lastDelay)
        
        lastDelay = jitteredDelay
        
        backoffMetrics.recordDelayCalculation(
            attempt: attempt,
            rawDelay: rawDelay,
            jitteredDelay: jitteredDelay
        )
        
        print("[ExponentialBackoffManager] Attempt \(attempt): raw=\(String(format: "%.2fs", rawDelay)), jittered=\(String(format: "%.2fs", jitteredDelay))")
        
        return jitteredDelay
    }
    
    func reset() {
        print("[ExponentialBackoffManager] Resetting backoff state")
        _currentAttempt = 0
        lastDelay = 0
        backoffMetrics.recordReset()
    }
    
    func incrementAttempt() -> TimeInterval {
        _currentAttempt += 1
        return calculateDelay(for: _currentAttempt)
    }
    
    func hasExceededMaxAttempts() -> Bool {
        return _currentAttempt >= maxAttempts
    }
    
    func getMetrics() -> BackoffMetrics {
        return backoffMetrics
    }
    
    // MARK: - Private Implementation
    
    private func calculateRawDelay(for attempt: Int) -> TimeInterval {
        switch strategy {
        case .exponential(let base, let multiplier, let maxDelay):
            let delay = base * pow(multiplier, Double(attempt - 1))
            return min(delay, maxDelay)
            
        case .fibonacci(let base, let maxDelay):
            let fibValue = fibonacci(attempt)
            let delay = base * fibValue
            return min(delay, maxDelay)
            
        case .linear(let interval, let maxDelay):
            let delay = interval * Double(attempt)
            return min(delay, maxDelay)
        }
    }
    
    private func fibonacci(_ n: Int) -> TimeInterval {
        if let cached = fibonacciCache[n] {
            return cached
        }
        
        if n <= 1 {
            return 1
        }
        
        let value = fibonacci(n - 1) + fibonacci(n - 2)
        fibonacciCache[n] = value
        return value
    }
}

// MARK: - Circuit Breaker

enum CircuitBreakerState {
    case closed     // Normal operation
    case open       // Failing, reject all attempts
    case halfOpen   // Testing if service recovered
}

final class CircuitBreaker {
    
    // Configuration
    private let failureThreshold: Int
    private let successThreshold: Int
    private let timeout: TimeInterval
    private let rollingWindowDuration: TimeInterval
    
    // State
    private var state: CircuitBreakerState = .closed
    private var failureCount: Int = 0
    private var successCount: Int = 0
    private var lastFailureTime: Date?
    private var stateChangeTime: Date = Date()
    
    // Rolling window for failures
    private var recentFailures: [Date] = []
    
    // Thread safety
    private let lock = NSLock()
    
    init(failureThreshold: Int = 5,
         successThreshold: Int = 3,
         timeout: TimeInterval = 60.0,
         rollingWindowDuration: TimeInterval = 120.0) {
        self.failureThreshold = failureThreshold
        self.successThreshold = successThreshold
        self.timeout = timeout
        self.rollingWindowDuration = rollingWindowDuration
        
        print("[CircuitBreaker] Initialized: failure threshold=\(failureThreshold), success threshold=\(successThreshold), timeout=\(timeout)s")
    }
    
    func canAttemptConnection() -> Bool {
        return lock.withLock {
            updateState()
            
            switch state {
            case .closed:
                return true
            case .open:
                return false
            case .halfOpen:
                return true // Allow test attempts
            }
        }
    }
    
    func recordSuccess() {
        lock.withLock {
            print("[CircuitBreaker] Recording success")
            
            switch state {
            case .closed:
                // Reset failure count on success
                failureCount = 0
                
            case .halfOpen:
                successCount += 1
                if successCount >= successThreshold {
                    print("[CircuitBreaker] Success threshold reached - closing circuit")
                    transitionTo(.closed)
                }
                
            case .open:
                // Shouldn't happen, but reset if it does
                print("[CircuitBreaker] Unexpected success in open state")
                transitionTo(.halfOpen)
            }
        }
    }
    
    func recordFailure() {
        lock.withLock {
            print("[CircuitBreaker] Recording failure")
            
            let now = Date()
            lastFailureTime = now
            recentFailures.append(now)
            
            // Clean old failures outside rolling window
            let cutoffTime = now.addingTimeInterval(-rollingWindowDuration)
            recentFailures = recentFailures.filter { $0 >= cutoffTime }
            
            switch state {
            case .closed:
                if recentFailures.count >= failureThreshold {
                    print("[CircuitBreaker] Failure threshold reached - opening circuit")
                    transitionTo(.open)
                }
                
            case .halfOpen:
                print("[CircuitBreaker] Failure in half-open state - reopening circuit")
                transitionTo(.open)
                
            case .open:
                // Already open, just record the failure
                break
            }
        }
    }
    
    func getCurrentState() -> CircuitBreakerState {
        return lock.withLock {
            updateState()
            return state
        }
    }
    
    func getMetrics() -> CircuitBreakerMetrics {
        return lock.withLock {
            return CircuitBreakerMetrics(
                currentState: state,
                failureCount: recentFailures.count,
                successCount: successCount,
                timeInCurrentState: Date().timeIntervalSince(stateChangeTime),
                lastFailureTime: lastFailureTime,
                totalStateChanges: 0 // Would need to track this
            )
        }
    }
    
    // MARK: - Private Implementation
    
    private func updateState() {
        switch state {
        case .closed:
            // Check if we should open due to recent failures
            let now = Date()
            let cutoffTime = now.addingTimeInterval(-rollingWindowDuration)
            recentFailures = recentFailures.filter { $0 >= cutoffTime }
            
            if recentFailures.count >= failureThreshold {
                transitionTo(.open)
            }
            
        case .open:
            // Check if timeout has elapsed to transition to half-open
            let timeSinceStateChange = Date().timeIntervalSince(stateChangeTime)
            if timeSinceStateChange >= timeout {
                print("[CircuitBreaker] Timeout elapsed - transitioning to half-open")
                transitionTo(.halfOpen)
            }
            
        case .halfOpen:
            // State changes are handled by recordSuccess/recordFailure
            break
        }
    }
    
    private func transitionTo(_ newState: CircuitBreakerState) {
        let oldState = state
        state = newState
        stateChangeTime = Date()
        
        // Reset counters based on new state
        switch newState {
        case .closed:
            failureCount = 0
            successCount = 0
        case .open:
            successCount = 0
        case .halfOpen:
            successCount = 0
        }
        
        print("[CircuitBreaker] State transition: \(oldState) -> \(newState)")
    }
}

// MARK: - Metrics Structures

struct BackoffMetrics {
    private(set) var totalCalculations: Int = 0
    private(set) var averageRawDelay: TimeInterval = 0
    private(set) var averageJitteredDelay: TimeInterval = 0
    private(set) var totalResets: Int = 0
    
    private var totalRawDelay: TimeInterval = 0
    private var totalJitteredDelay: TimeInterval = 0
    
    mutating func recordDelayCalculation(attempt: Int, rawDelay: TimeInterval, jitteredDelay: TimeInterval) {
        totalCalculations += 1
        totalRawDelay += rawDelay
        totalJitteredDelay += jitteredDelay
        
        averageRawDelay = totalRawDelay / Double(totalCalculations)
        averageJitteredDelay = totalJitteredDelay / Double(totalCalculations)
    }
    
    mutating func recordReset() {
        totalResets += 1
    }
}

struct CircuitBreakerMetrics {
    let currentState: CircuitBreakerState
    let failureCount: Int
    let successCount: Int
    let timeInCurrentState: TimeInterval
    let lastFailureTime: Date?
    let totalStateChanges: Int
}