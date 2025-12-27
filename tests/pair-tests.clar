;; Basic Clarinet tests for pair contract
;; Adjust test syntax for your Clarinet version if needed.

(begin-test init-and-swap
  (let ((res (contract-call? .pair initialize u1000 u1000)))
    (asserts! (is-ok res) "initialize-ok")
    (let ((r (contract-call? .pair get-reserves)))
      (asserts! (is-ok r) "get-reserves-ok"))))

(begin-test mint-and-burn-liquidity
  (let ((res (contract-call? .pair initialize u1000 u1000)))
    (asserts! (is-ok res) "initialize-ok")
    (let ((mint (contract-call? .pair mint-liquidity u100 u100)))
      (asserts! (is-ok mint) "mint-ok")
      (let ((burn (contract-call? .pair burn-liquidity u10 tx-sender)))
        (asserts! (is-ok burn) "burn-ok")))))

(begin-test swap-behavior
  (let ((res (contract-call? .pair initialize u1000 u1000)))
    (asserts! (is-ok res) "initialize-ok")
    ;; valid swap should return ok
    (let ((out (contract-call? .pair swap-a-for-b u100 u0)))
      (asserts! (is-ok out) "swap-ok"))
    ;; zero input should error
    (let ((err-res (contract-call? .pair swap-a-for-b u0 u0)))
      (asserts! (is-err err-res) "zero-input-err"))))

(begin-test swap-slippage
  (let ((res (contract-call? .pair initialize u1000 u1000)))
    (asserts! (is-ok res) "initialize-ok")
    ;; request an unrealistically high min-out to trigger slippage error
    (let ((maybe (contract-call? .pair swap-a-for-b u100 u999999)))
      (asserts! (is-err maybe) "slippage-err"))))
