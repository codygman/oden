(define (ping-ponger (name string)
                     (in (chan int))
                     (out (chan int))
                     (res (chan string))
                     unit)
    (let loop ((n (!< in)))
         (if (> n 0)
             (do
              (fmt/Println name n)
              (!> out (- n 1))
               (loop (!< in)))
             (!> res "Done"))))

(define (ping-pong-2 string)
    (let ((a (chan))
          (b (chan))
          (res (chan)))
      (go (ping-ponger "ping" a b res))
      (go (ping-ponger "pong" b a res))
      (!> a 10)
      (!< res)))