#lang r7rs
(import (scheme base)
        (scheme read)
        (scheme write)
        (scheme file)
        (prefix (a-d graph weighted with-self-loops config) wg:)
        (prefix (a-d graph unweighted config) ug:)
        (prefix (a-d graph examples undirected-unweighted) ex:)
        (a-d louvain))

; Procedure to read a graph from file
(define (read-graph-from-file file directed? initial-weight)
  (with-input-from-file file
    (lambda ()
      (let* ((num-nodes (read (current-input-port)))
             (graph (wg:new directed? num-nodes)))
        (do ((entry (read (current-input-port))
                    (read (current-input-port))))
          ((eof-object? entry) )
          (wg:add-edge! graph (- (car entry) 1) (- (cadr entry) 1)
                        initial-weight))
        graph))))

; Procedure to transform an unweighted graph to a weighted graph given an initial weight
(define (to-weighted-graph unweighted-graph initial-weight)
  (let ((graph (wg:new (ug:directed? unweighted-graph)
                       (ug:order unweighted-graph))))
    (ug:for-each-node
     unweighted-graph
     (lambda (from)
       (ug:for-each-edge 
        unweighted-graph
        from
        (lambda (to)
          (wg:add-edge! graph
                        from
                        to
                        initial-weight)))))
    graph))

; Some example graphs
(define blondel (read-graph-from-file "examples/blondel.txt" #f 1))
(define club (read-graph-from-file "examples/karate-club.txt" #f 1))
(define connected (to-weighted-graph ex:connected 1))

; Demonstrate the Louvain Method on some graphs
;(display (detect-communities blondel))
;(display (detect-communities club))

;(display (louvain blondel))
;(display (louvain club))
;(display (louvain connected))

