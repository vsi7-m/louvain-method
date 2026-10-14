#lang r7rs

;-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
;-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
;-*-*                                                                 *-*-
;-*-*               Weighted Graphs (Configuration File)              *-*-
;-*-*                        with self-loops                          *-*-
;-*-*                                                                 *-*-
;-*-*                                                                 *-*-
;-*-*           Edited by Youri Coppens and Doryan Temmerman          *-*-
;-*-*                                                                 *-*-
;-*-*                       Wolfgang De Meuter                        *-*-
;-*-*                   2009  Software Languages Lab                  *-*-
;-*-*                    Vrije Universiteit Brussel                   *-*-
;-*-*                                                                 *-*-
;-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
;-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-

(define-library (weighted-graph)
 (export new weighted-graph? for-each-node for-each-edge
         add-edge! delete-edge! nr-of-edges
         adjacent? weight directed? order)
 (import (scheme base)
         (a-d graph weighted with-self-loops adjacency-list)
         ;(a-d graph weighted with-self-loops adjacency-matrix)
         )
 )