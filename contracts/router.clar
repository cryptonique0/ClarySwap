;; router.clar
;; Router for single-hop and multi-hop swaps across pair contracts.
;; Supports path-based routing for optimal pricing.

;; Error codes
(define-constant err-invalid-path (err "invalid-path"))
(define-constant err-slippage (err "slippage-exceeded"))
(define-constant err-expired (err "deadline-expired"))

;; Single-hop swap via pair contract
(define-public (swap-single-hop (pair-contract principal) (a-to-b bool) (amount-in uint) (min-amount-out uint) (deadline uint))
  (begin
    (asserts! (< block-height deadline) err-expired)
    (if a-to-b
      (contract-call? pair-contract swap-a-for-b amount-in min-amount-out)
      (contract-call? pair-contract swap-b-for-a amount-in min-amount-out))))

;; Multi-hop swap: 2 hops (A → B → C)
(define-public (swap-two-hop 
  (pair1 principal) 
  (pair2 principal) 
  (a-to-b-1 bool) 
  (a-to-b-2 bool) 
  (amount-in uint) 
  (min-amount-out uint)
  (deadline uint))
  (begin
    (asserts! (< block-height deadline) err-expired)
    ;; First hop
    (match (if a-to-b-1
             (contract-call? pair1 swap-a-for-b amount-in u0)
             (contract-call? pair1 swap-b-for-a amount-in u0))
      intermediate-out
        ;; Second hop
        (match (if a-to-b-2
                 (contract-call? pair2 swap-a-for-b intermediate-out min-amount-out)
                 (contract-call? pair2 swap-b-for-a intermediate-out min-amount-out))
          final-out (ok final-out)
          err2 (err err2))
      err1 (err err1))))

;; Quote helper for off-chain estimation (read-only)
(define-read-only (quote-output (amount-in uint) (reserve-in uint) (reserve-out uint))
  (if (or (is-eq amount-in u0) (is-eq reserve-in u0) (is-eq reserve-out u0))
    (ok u0)
    (let ((amount-in-with-fee (/ (* amount-in u997) u1000)))
      (let ((numerator (* amount-in-with-fee reserve-out))
            (denom (+ reserve-in amount-in-with-fee)))
        (ok (/ numerator denom))))))
