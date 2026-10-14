#lang r7rs
(define-library (louvain-method)
  (export louvain detect-communities aggregate degrees modularity in-community-degree) ; DO NOT CHANGE THIS LINE
  (import (scheme base)
          ;(scheme write)
          (scheme cxr)
          (prefix (a-d graph weighted with-self-loops config) g:)
          (prefix (a-d dictionary ordered avl) d:))
  (begin

    ;;;; MANDATORY Auxiliary procedures 

    ; degrees (weighted-graph -> vector<number>)
    ; Returns a node-indexed vector containing the degree of each node of a weighted graph
    (define (degrees graph)
      (let ((degree (make-vector (g:order graph) 0))) 
        (g:for-each-node graph 
                         (lambda (node) 
                           (let ((total 0)) 
                             (g:for-each-edge graph node
                                              (lambda (weight to)
                                                (set! total (+ total weight)))) 
                             (vector-set! degree node total)))) 
        degree))

    ; modularity (weighted-graph vector<community-id> -> number)
    ; General formula to calculate modularity in a weighted graph given its communities
    (define (modularity graph communities)
      (let* ((degree (degrees graph))
             (W (apply + (vector->list degree)))
             (Q 0))
        (g:for-each-node graph
                         (lambda (i)
                           (g:for-each-node graph 
                                            (lambda (j)
                                              (let ((ci (vector-ref communities i)) 
                                                    (cj (vector-ref communities j))
                                                    (ki (vector-ref degree i))
                                                    (kj (vector-ref degree j))
                                                    (wij (g:weight graph i j)))
                                                (if (= ci cj)
                                                    (set! Q (+ Q
                                                               (if (g:adjacent? graph i j) ; YAAAAAYY
                                                                   wij
                                                                   0)
                                                               (- (/ (* ki kj) W))))))))))
        (/ Q W)))
                                                                      

    ; in-community-degree (weighted-graph vector<community-id> number community-id -> number)
    ; Procedure to calculate the sum of weights of edges from a specific node leading to other nodes in a specific community.
    (define (in-community-degree graph communities node comm-id)
      (let ((total 0))
        (g:for-each-edge graph node
                         (lambda (weight to)
                           (when (and (not (= node to)) ; geen zelfbogen tellen
                                      (= (vector-ref communities to) comm-id)) 
                             (set! total (+ total weight)))))
        total))


    ;;;; PHASE 1: Modularity Optimization

    ; detect-communities (weighted-graph -> {number, vector<community-id>, dictionary<community-id, number>} )
    ; Assigns nodes of a weighted graph to a community by optimizing modularity.
    ; Returns a list containing:
    ;     (1) the amount of improvement in modularity that was made;
    ;     (2) a node-indexed vector of community id's;
    ;     (3) a dictionary mapping communities to their internal degree 
    (define (detect-communities graph)
      (define (sig-tot communities degree comm-id)
        (let ((total 0))
          (g:for-each-node graph
                           (lambda (i)
                             (when (= (vector-ref communities i) comm-id)
                               (set! total (+ total (vector-ref degree i))))))
          total))
      
      (let* ((n (g:order graph))
             (communities (make-vector n -1))
             (degree (degrees graph))
             (W (apply + (vector->list degree)))
             (intra-degrees (d:new = <))
             (tot-delta-Q 0))
        ;(display "communities and intra-degrees initialisation: ") (newline)
        (g:for-each-node graph
                         (lambda (node)
                           (vector-set! communities node node)
                           (let ((comm-id (vector-ref communities node))
                                 (self-loop (if (g:adjacent? graph node node)
                                                (g:weight graph node node)
                                                0)))
                             ;(display "node: ") (display node) (display " - in-com-deg = ") (display (in-community-degree graph communities node comm-id)) (newline)
                             (d:insert! intra-degrees comm-id (+ self-loop (in-community-degree graph communities node comm-id))))))
        ;(display "initial communities: ") (display communities) (newline)
        ;(display "initial intra-degrees: ") (display intra-degrees) (newline)
        ;(display "degrees: ") (display degree) (newline)
        
        (let iter-nodes ((best-delta-Q -1)
                         (best-comm (vector-ref communities 0))
                         (moved? #f))
          (g:for-each-node graph
                           (lambda (node)
                             ;(newline) (display "processing node ") (display node) (newline)
                             (let ((neighbor-comms '())
                                   (comm-id (vector-ref communities node)))
                               (g:for-each-node graph
                                                (lambda (to)
                                                  (let ((neighbor-id (vector-ref communities to)))
                                                    (when (and (g:adjacent? graph node to)
                                                               (not (member neighbor-id neighbor-comms)))
                                                      (set! neighbor-comms (cons neighbor-id neighbor-comms))))))

                               (let iter-neighbors ((comms neighbor-comms))
                                 (when (not (null? comms))
                                   ;(display " checking to community ") (display neighbor-comm) 
                                   (let* ((neighbor-comm (car comms))
                                          (rest (cdr comms))
                                          (kiA (in-community-degree graph communities node comm-id))
                                          (kiB (in-community-degree graph communities node neighbor-comm))
                                          (ki (vector-ref degree node))
                                          (sig-totA (sig-tot communities degree comm-id))
                                          (sig-totB (sig-tot communities degree neighbor-comm))
                                          (delta-Q (/ (+ (- (* 2 kiB)
                                                            (* 2 kiA))
                                                         (* (/ (* 2 ki) W)
                                                            (- sig-totA ki sig-totB)))
                                                      W)))
                                     ;(display " deltaQ =") (display delta-Q) (newline)
                                     (when (> delta-Q best-delta-Q)
                                       (set! best-delta-Q delta-Q)
                                       (set! best-comm neighbor-comm))
                                     (iter-neighbors rest))))
                               
                               (when (> best-delta-Q 0)
                                 ;(display "moving node ") (display node) (display " from community ") (display comm-id) (display " to community ") (display best-comm)
                                 ;(display " deltaQ = ") (display best-delta-Q) (newline)
                                 (set! moved? #t)
                                 (set! tot-delta-Q (+ tot-delta-Q best-delta-Q))
                                 (set! best-delta-Q -1)
                                 (let ((kiA (in-community-degree graph communities node comm-id))
                                       (kiB (in-community-degree graph communities node best-comm))
                                       (self-loop (if (g:adjacent? graph node node)
                                                      (g:weight graph node node)
                                                      0)))
                                   (d:insert! intra-degrees comm-id (- (d:find intra-degrees comm-id) (* 2 kiA) self-loop))
                                   (d:insert! intra-degrees best-comm (+ (d:find intra-degrees best-comm) (* 2 kiB) self-loop))
                                   (vector-set! communities node best-comm))))))
          (when moved?
            ;(display "-------New iteration-------") (newline)
            (iter-nodes -1 (vector-ref communities 0) #f)))

        ;(display "===========Result: ") (newline)
        ;(display "tot-DQ=") (display tot-delta-Q) (newline)
        ;(display "communities: ") (display communities) (newline)
        ;(display "intra-degrees: ") (display intra-degrees) (newline) (newline)
        (list tot-delta-Q communities intra-degrees)))
                                                

    ;;;; PHASE 2: Community Aggregation
 
    ; aggregate (weighted-graph vector<community-id> dictionary<community-id, number> -> weighted-graph)
    ; Generates the aggregated weighted graph given:
    ;     (1) a weighted graph;
    ;     (2) a node-indexed vector of its communities;
    ;     (3) a dictionary mapping communities to their intra-degree 
    (define (aggregate graph communities sigma-ins)
      (let* ((comm-ids
              (let iter ((i 0)
                         (comms '()))
                (if (= i (vector-length communities))
                    comms
                    (if (member (vector-ref communities i) comms)
                        (iter (+ i 1) comms)
                        (iter (+ i 1) (cons (vector-ref communities i) comms))))))
             
             (new-comm-ids
              (let iter ((ids comm-ids)
                         (i 0)
                         (d (d:new = <)))
                (if (null? ids)
                    d
                    (iter (cdr ids) (+ i 1) (d:insert! d (car ids) i)))))
            
             (comm-count (length comm-ids))
             (new-graph (g:new #f comm-count))
             (edge-weights (d:new equal? (lambda (p1 p2)
                                        (or (< (car p1) (car p2))
                                            (and (= (car p1) (car p2))
                                                 (< (cdr p1) (cdr p2)))))))
             (edges '()))
        ;(display "new community ids ") (display new-comm-ids) (newline)

        (let self-loops ((current (car comm-ids))
                         (rest (cdr comm-ids)))
          (g:add-edge! new-graph (d:find new-comm-ids current) (d:find new-comm-ids current) (d:find sigma-ins current))
          (when (not (null? rest))
            (self-loops (car rest) (cdr rest))))
         
        (g:for-each-node graph
                         (lambda (i)
                           ;(display "node i ") (display i) (newline)
                           (g:for-each-edge graph i
                                            (lambda (weight j)
                                              (when (< i j)
                                                (let* ((ci (vector-ref communities i))
                                                       (cj (vector-ref communities j))
                                                       (new-ci (d:find new-comm-ids ci))
                                                       (new-cj (d:find new-comm-ids cj)))
                                                  (when (not (= new-ci new-cj))
                                                    (let ((key (if (< new-ci new-cj)
                                                                   (cons new-ci new-cj)
                                                                   (cons new-cj new-ci))))
                                                      (d:insert! edge-weights key (+ (or (d:find edge-weights key) 0)
                                                                                     weight))
                                                      (when (not (member key edges))
                                                        (set! edges (cons key edges)))))))))))
        ;(display "edge weights: ") (display edge-weights) (newline)))))
        (for-each (lambda (key)
                    (let* ((weight (d:find edge-weights key))
                           (ci (car key))
                           (cj (cdr key)))
                      (g:add-edge! new-graph ci cj weight)))
                  edges)
        ;(display "nieuwe graaf ") (display new-graph)
        new-graph))
      
                                                                 

    ;;;; The top-level structure of the Louvain Method

    ; DO NOT CHANGE THIS PROCEDURE
    (define (louvain graph)
      (let iter ((hierarchy '())
                 (current-graph graph))
        (let* ((first-phase (detect-communities current-graph))
               (improvement (car first-phase))
               (communities (cadr first-phase))
               (sigma-ins (caddr first-phase)))
          (if (> improvement 0) ; As long as we can improve modularity, we continue
              (iter (cons (cons current-graph communities)
                          hierarchy)
                    (aggregate current-graph communities sigma-ins))
              (cons (cons current-graph communities)
                    hierarchy)))))
    ))