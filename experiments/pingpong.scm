;; pingpong.km (.scm extension is just for syntax highlighting)
(define (ping-pong string)
    (let ((a (chan))
          (b (chan))
          (res (chan))
          (f (lambda (name in out)
               (let loop ((n (!< in)))
                 (if (> n 0)
                     (do
                      (fmt/Println name n)
                      (!> out (- n 1))
                      (loop (!< in)))
                     (!> res "Done"))))))
      (go (f "ping" a b))
      (go (f "pong" b a))
      (!> a 10)
      (!< res)))