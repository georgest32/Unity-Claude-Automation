# Week 3 Day 2 - Incremental Processing Research Findings

**Date & Time**: 2025-08-28 22:15:00  
**Research Queries Performed**: 5  
**Focus Areas**: FileSystemWatcher, Hashing Performance, Incremental Updates, Diff Algorithms

## Key Research Findings

### 1. FileSystemWatcher Performance Considerations

**Limitations**:
- Not stable for rapid events (can miss changes)
- Buffer overflow issues with high-volume changes
- Lost events when PowerShell is busy processing
- Considered "leaky abstraction" - not 100% reliable

**Best Practices**:
- Use 16MB buffer for large batches (production proven)
- Combine with periodic polling for reliability
- Process events asynchronously via queue
- Cache file names before processing

### 2. File Hashing Performance

**Algorithm Comparison**:
- MD5: Faster for non-security tasks, but deprecated
- SHA256: Modern processors have crypto acceleration
- Optimal buffer size: 64KB (25% performance increase)
- Small files: Opening/closing overhead dominates hash time

**Optimization Tips**:
- Use parallel processing for multiple files
- Cache previous hash results
- For <16KB files, no performance penalty with larger buffers
- System32 directory test: 10.4s → 9.0s with 64KB buffer

### 3. PowerShell Diff Performance

**Compare-Object Issues**:
- O(n²) complexity - compares every element
- Very slow for large datasets
- Creates PSCustomObject wrapper overhead

**Optimization Strategies**:
- Use HashSet[T] for O(1) lookups
- SyncWindow parameter for position-based matching
- PassThru parameter to avoid wrapper overhead
- LINQ SequenceEqual for native performance
- Generic Lists instead of arrays

### 4. Incremental Graph Updates (2024 Research)

**Advanced Techniques**:
- IncBoost: Handles 30-60% graph updates efficiently
- Differential Analysis: Only analyzes changed files in CI/CD
- IncA DSL: Domain-specific language for incremental analysis
- Two-pass approach maintains precision

**Performance Gains**:
- 3.1× speedup for edge deletions
- 5.2× speedup for weight updates
- Avoids resetting dataflow solutions

### 5. Memory-Efficient Change Tracking

**Hybrid Approach**:
- LastWriteTime for initial filtering
- Checksums only for changed files
- ConcurrentDictionary for thread-safe caching
- Runspace pools with 10-20 threads

**100 Files/Second Challenge**:
- Pure PowerShell struggles with this target
- IO-bound operations limit parallelization benefit
- Recommended: Queue-based processing with batching

## Implementation Recommendations

### Core Architecture
1. **Change Detection Layer**
   - Timer-based polling (more reliable than FileSystemWatcher)
   - LastWriteTime for primary detection
   - SHA256 for verification (hardware accelerated)

2. **Processing Pipeline**
   - Queue-based architecture
   - Runspace pool (10-20 threads)
   - Synchronized hashtable for shared state
   - 64KB buffer size for file operations

3. **Optimization Techniques**
   - Batch processing for efficiency
   - Cache file metadata (size, LastWriteTime, hash)
   - Skip unchanged files based on LastWriteTime
   - Process only deltas in graph updates

4. **Memory Management**
   - ConcurrentDictionary for cache
   - LRU eviction for cache size control
   - Dispose patterns for resource cleanup
   - Limit in-memory graph size

## Performance Targets Analysis

**100 Files/Second Feasibility**:
- Achievable for metadata checking (LastWriteTime)
- Challenging for full content hashing
- Requires hybrid approach and optimization
- Consider native components for critical paths

## Critical Learnings

1. **FileSystemWatcher is unreliable** - Use polling + queue approach
2. **64KB buffer size** is optimal for file operations
3. **HashSet lookups** are 100x faster than Compare-Object
4. **LastWriteTime + Hash** hybrid gives best performance/accuracy
5. **Runspace pools** required for true parallelization

---
*Research phase complete. Ready to implement based on findings.*