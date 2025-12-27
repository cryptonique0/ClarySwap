;; analytics.clar
;; On-chain analytics tracking for pool metrics
;; Tracks 24h volume, fees accrued, and historical data

(define-map pool-stats
  (tuple (pair-contract principal))
  (tuple 
    (total-volume uint)
    (total-fees uint)
    (swap-count uint)
    (last-update uint)))

(define-map daily-volume
  (tuple (pair-contract principal) (day uint))
  (tuple (volume uint) (fees uint) (swaps uint)))

(define-constant BLOCKS_PER_DAY u144) ;; Approx 24h with 10min blocks
(define-constant ERR_UNAUTHORIZED "unauthorized")

;; --- Track swap event ---
(define-public (record-swap (pair-contract principal) (volume uint) (fee uint))
  ;; In production, verify caller is authorized pair contract
  (let ((current-day (/ block-height BLOCKS_PER_DAY))
        (current-stats (default-to 
          (tuple (total-volume u0) (total-fees u0) (swap-count u0) (last-update u0))
          (map-get? pool-stats (tuple (pair-contract pair-contract)))))
        (daily-stats (default-to
          (tuple (volume u0) (fees u0) (swaps u0))
          (map-get? daily-volume (tuple (pair-contract pair-contract) (day current-day))))))
    (begin
      ;; Update total stats
      (map-set pool-stats 
        (tuple (pair-contract pair-contract))
        (tuple 
          (total-volume (+ (get total-volume current-stats) volume))
          (total-fees (+ (get total-fees current-stats) fee))
          (swap-count (+ (get swap-count current-stats) u1))
          (last-update block-height)))
      ;; Update daily stats
      (map-set daily-volume
        (tuple (pair-contract pair-contract) (day current-day))
        (tuple
          (volume (+ (get volume daily-stats) volume))
          (fees (+ (get fees daily-stats) fee))
          (swaps (+ (get swaps daily-stats) u1))))
      (ok true))))

;; --- Read-only queries ---
(define-read-only (get-pool-stats (pair-contract principal))
  (ok (map-get? pool-stats (tuple (pair-contract pair-contract)))))

(define-read-only (get-24h-volume (pair-contract principal))
  (let ((current-day (/ block-height BLOCKS_PER_DAY)))
    (ok (map-get? daily-volume (tuple (pair-contract pair-contract) (day current-day))))))

(define-read-only (get-historical-volume (pair-contract principal) (day uint))
  (ok (map-get? daily-volume (tuple (pair-contract pair-contract) (day day)))))

;; --- Calculate TVL (requires external price oracle in production) ---
(define-read-only (estimate-tvl (pair-contract principal) (reserve-a uint) (reserve-b uint) (price-a uint) (price-b uint))
  ;; Simple TVL calculation: (reserve-a * price-a) + (reserve-b * price-b)
  ;; Prices should be in standardized units (e.g., USD with 6 decimals)
  (ok (+ (* reserve-a price-a) (* reserve-b price-b))))
