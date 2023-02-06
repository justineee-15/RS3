;; make them slowly move towards their designated place
;; calibrate time
;; fix the linking system
;; no infection yet for research or sets

turtles-own
[
  ;; this is used to mark turtles we have already visited
  explored?
  infected?           ;; if true, the turtle is infectious
  resistant?          ;; if true, the turtle can't be infected
  vaccinated?         ;; if true, the turtle is vaccinated
  recovering?         ;; really, this is just for efficiency
  virus-check-timer   ;; number of ticks since this turtle's last virus-check
  day-of-infection    ;; day they got infected
  time-of-infection   ;; time they got infected


  base_xcor
  base_ycor

  scale
  scale_xcor
  scale_ycor
  humanities
  humanities_xcor
  humanities_ycor
  core
  elective
  math-section
  research
  core-set
  elective-set
  inactive-set

  a_xcor
  a_ycor
  b_xcor
  b_ycor
  c_xcor
  c_ycor
  move
;  moved?
]

undirected-link-breed [ friend-links friend-link]
undirected-link-breed [ scale-links scale-link ]
undirected-link-breed [ humanities-links humanities-link ]
undirected-link-breed [ core-links core-link ]
undirected-link-breed [ elective-links elective-link ]
undirected-link-breed [ math-section-links math-section-link ]
undirected-link-breed [ research-links research-link ]

globals
[
  component-size          ;; number of turtles explored so far in the current component
  giant-component-size    ;; number of turtles in the giant component
  giant-start-node        ;; node from where we started exploring the giant component
  done?
  instant?
  day
  time
  current-period
  total-infected
  layout?

  divide_3
  divide_4
  divide_5
]

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

;; the number of connections made can matter based on the population around them

to instant-go-1
  loop [
    let a 0
    if done? = true [stop]
    if-else any? turtles with [color = 7] [
      instant-go
    ]
    [ set a 1 ]
    if a = 1 and done? = false [
      if layout? [
        repeat 200 [
          layout-spring (turtles with [any? friend-link-neighbors]) links 0.3 150 200
          ;layout-tutte (turtles with [count link-neighbors > 1]) links 200+
        ]
      ]

      ask turtles [
        set base_xcor xcor
        set base_ycor ycor
      ]

      ask n-of (initial-outbreak-size) turtles [ become-infected ]
    ;  ask n-of 5 turtles with [infected? = false] [become-resistant]
      set done? true
      stop
    ]
  ]
end

to setup
  clear-all
  set-default-shape turtles "person"
  set divide_5 [ -73.47315653655913 -101.12712429686843 118.88206453689419 38.62712429686843 0 125 -118.8820645368942 38.6271242968684 73.47315653655916 -101.12712429686842 ]
  set divide_3 [-86.60254037844385 -50.00000000000004 86.60254037844388 -49.99999999999998 0 100]
  set divide_4 [125 125 -125 -125 125 -125 -125 125]
  make-turtles
  set done? false
  ;; at this stage, all the components will be of size 1,
  ;; since there are no edges yet
  ask links [hide-link]
  find-all-components
  color-giant-component
  reset-ticks
  set layout? true
end

to make-turtles
  create-turtles num-nodes [
    set size 15
    set infected? false
    set resistant? false
    set recovering? false
    set virus-check-timer random virus-check-frequency
    set elective (random 9)
    set core (random 3)
    if elective <= 4 [
      while [core = (floor (elective / 2))] [
        set core (random 3)
      ]
    ]
  ]

  let x 1
  while [x < 5] [
    ask n-of ((count turtles) / 5) turtles with [scale = 0] [
      set scale x
    ]
    set x x + 1
  ]
  set x 1
  ask n-of 75 turtles [
    set research x
    set x (x + 1)
    if (x = 26) [set x 1]
  ]
  set x 52
  ask n-of 10 turtles with [research = 0] [
    set research (floor (x / 2))
    set x (x + 1)
  ]

  ask turtles [
    let my-research [research] of self
    if my-research != 0 [ create-research-links-with other turtles with [research = my-research]]
  ]

  ask n-of ((count turtles) * vaccinated-percentage / 100) turtles [ set vaccinated? true ]
  ask turtles with [vaccinated? != true] [set vaccinated? false]
  ask n-of ((count turtles) / 3) turtles with [humanities = 0] [ set humanities 1 ]
  ask n-of ((count turtles) / 3) turtles with [humanities = 0] [ set humanities 2 ]

  ask turtles [
    (if-else elective >= 7 [
      set elective-set 2
    ]
    elective = 5 or elective = 6 [
      set elective-set 1
    ]
    elective = 0 [
      set elective-set 0
    ]
    elective = 2 [
      set elective-set 2
    ]) ;; 1 (0), 3 (1), and 4 (2) are treated as cores
    if core = 0 and (elective = 2 or elective >= 7) [
      set core-set 1
    ]
    if core = 0 and (elective = 5 or elective = 6) [
      set core-set 2
    ]
    if core = 1 and (elective = 5 or elective = 6) [
      set core-set 0
    ]
    if core = 1 and elective = 0 [
      set core-set 1
    ]
    if core = 2 and (elective = 2 or elective >= 7) [
      set core-set 0
    ]
    if core = 2 and elective = 0 [
      set core-set 2
    ]
  ]

  ask n-of abs((count turtles with [core = 0 or elective = 1]) / 2 - (count turtles with [core = 0 and core-set = 1])) turtles with [(core = 0 and core-set != 1 and elective-set != 1) or elective = 1] [
    if core = 0 [set core-set 1]
    if elective = 1 [set elective-set 1]
  ]
  ask turtles with [core = 0 and core-set != 1] [set core-set 2]
  ask turtles with [elective = 1 and elective-set != 1] [set elective-set 2]


  ask n-of abs((count turtles with [core = 1 or elective = 3]) / 2 - (count turtles with [core = 1 and core-set = 1])) turtles with [(core = 1 and core-set != 1 and elective-set != 1) or (elective = 3 and core-set != 1)] [
    if core = 1 [set core-set 1]
    if elective = 3 [set elective-set 1]
  ]

  ask turtles with [core = 1 and core-set = 0 and elective = 4] [set elective-set 2]
  ask turtles with [elective = 3 and elective-set = 0 and core = 2] [set core-set 2]


  if-else ((count turtles with [core = 2 or elective = 4]) / 2 - (count turtles with [core = 2 and core-set = 2]) - (count turtles with [elective = 4 and elective-set = 2])) >= (count turtles with [(core = 2 and core-set != 2 and elective-set != 2) or (elective = 4 and core-set != 2 and elective-set != 2)]) [
    if (count turtles with [core = 2 or elective = 4]) / 2 >= (count turtles with [core = 2 and core-set = 0]) + (count turtles with [elective = 4 and elective-set = 0]) [
      ask n-of (ceiling (count turtles with [core = 2 or elective = 4]) / 2 - (count turtles with [core = 2 and core-set = 0]) - (count turtles with [elective = 4 and elective-set = 0])) turtles with [(core = 2 and core-set != 0 and elective-set != 0) or (elective = 4 and core-set != 0 and elective-set != 0)] [
        if core = 2 [set core-set 0]
        if elective = 4 [set elective-set 0]
      ]
    ]
  ]
  [
    ask n-of abs((ceiling (count turtles with [core = 2 or elective = 4]) / 2) - (count turtles with [core = 2 and core-set = 2]) - (count turtles with [elective = 4 and elective-set = 2])) turtles with [(core = 2 and core-set != 2 and elective-set != 2) or (elective = 4 and core-set != 2 and elective-set != 2)] [
      if core = 2 [set core-set 2]
      if elective = 4 [set elective-set 2]
    ]
  ]

  ask turtles [
    set math-section random 3
    set inactive-set (3 - core-set - elective-set)
  ]

  setup_shc
  layout-circle (sort turtles) max-pxcor - 10
end

;;;;;;;;;;;;;;;;;;;;;;
;;; Main Procedure ;;;
;;;;;;;;;;;;;;;;;;;;;;

to go1
  set day 0
  set time 745

  let a 0
  add-specific-edge 0
  add-specific-edge 1
  add-specific-edge 2
  add-specific-edge 2
  add-specific-edge 3
  add-specific-edge 4
  add-specific-edge 5

  find-all-components
  color-giant-component
  ask links [ set color [color] of end1 ]  ;; recolor all edges
  ;; layout the turtles with a spring layout, but stop laying out when all nodes are in the giant component
  if not all? turtles [ color = blue ] [ layout ]
  ask links [
    set color white
    hide-link
  ]
  ask friend-links [show-link]
end

to instant-go
  set day 0
  set time 745
  set instant? true
  let a 0
  add-specific-edge 0
  add-specific-edge 1
  add-specific-edge 2
  add-specific-edge 2
  add-specific-edge 3
  add-specific-edge 3
  add-specific-edge 4
  add-specific-edge 4
  add-specific-edge 5
  find-all-components
  color-giant-component
  ask links [ set color [color] of end1 ]  ;; recolor all edges
  ;; layout the turtles with a spring layout, but stop laying out when all nodes are in the giant component
  if not all? turtles [ color = blue ] [ layout ]
  ask links [
    set color white
    hide-link
  ]
  ask friend-links [show-link]
end

to go2
  if not any? turtles with [infected? = true] [
    display
    stop
  ]
  if not layout? [ layout-circle (sort turtles) max-pxcor - 10 ]
  if ((day mod 7) = 5 or (day mod 7) = 6) or (ticks mod 5) = 0 [
    set time time + 5
    if (time mod 100) = 60 [
      set time time + 40
    ]
    if time = 1730 [
      set time 730
      set day day + 1
    ]
    clear-output
    output-type "Day: "
    output-print day
    output-type "Time: "
    output-print time
    output-type "Total: "
    output-print total-infected
  ]

  (ifelse (((day mod 7) = 0 and time >= 800 and time <= 840) or (day mod 7) = 2) [
    if current-period != "SCALE" [
      animate_move 1
      ask links [ hide-link ]
      ask scale-links [ show-link ]
      set current-period "SCALE"
    ]

  ]
  (((day mod 7) = 0 or (day mod 7) = 3) and time >= 800 and time <= 1040) or ((day mod 7) = 1 and time >= 800 and time <= 920)
  [
    if current-period != "Humanities" [
      animate_move 2
      ask links [ hide-link ]
      ask humanities-links [ show-link ]
      set current-period "Humanities"
    ]
  ]
  (((day mod 7) = 0 and time >= 1315 and time <= 1350) or ((day mod 7) = 1 and time >= 1055 and time <= 1215) or ((day mod 7) = 4 and time >= 800 and time <= 915))
  [
    if current-period != "Set A" [
      animate_move 3
      ask links [ hide-link ]
      ask turtles with [core-set = 0] [
        ask my-core-links [ show-link ]
      ]
      ask turtles with [elective-set = 0] [
        ask my-elective-links [ show-link ]
      ]
      set current-period "Set A"
    ]
  ]
  (((day mod 7) = 0 and time >= 1355 and time <= 1430) or ((day mod 7) = 3 and time >= 1435 and time <= 1555) or ((day mod 7) = 4 and time >= 1055 and time <= 1215))  ;; add more here!!!!!!!!!!!!!!!!
  [
    if current-period != "Set B" [
      animate_move 4
      ask links [ hide-link ]
      ask turtles with [core-set = 1] [
        ask my-core-links [ show-link ]
      ]
      ask turtles with [elective-set = 1] [
        ask my-elective-links [ show-link ]
      ]
      set current-period "Set B"
    ]
  ]
  (((day mod 7) = 0 and time >= 1435 and time <= 1515) or ((day mod 7) = 1 and time >= 1435 and time <= 1555) or ((day mod 7) = 4 and time >= 920 and time <= 1040))  ;; add more here!!!!!!!!!!!!!!!!
  [
    if current-period != "Set C" [
      animate_move 5
      ask links [ hide-link ]
      ask turtles with [core-set = 2] [
        ask my-core-links [ show-link ]
      ]
      ask turtles with [elective-set = 2] [
        ask my-elective-links [ show-link ]
      ]
      set current-period "Set C"
    ]
  ]
  (((day mod 7) = 1 and time >= 920 and time <= 1040) or (((day mod 7) = 3 or (day mod 7) = 4) and time >= 1315 and time <= 1430)) [
    if current-period != "Research" [
      animate_move 0
      ask links [hide-link]
      ask research-links [ show-link ]
      set current-period "Research"
    ]
  ]
  (((day mod 7) = 0 and time >= 1055 and time <= 1210) or ((day mod 7) = 1 and time >= 1315 and time <= 1430) or ((day mod 7) = 3 and time >= 1055 and time <= 1210))
  [
    if current-period != "Math" [
      animate_move 0
      ask links [hide-link]
      ask math-section-links [ show-link ]
      set current-period "Math"
    ]
  ]
  ((day mod 7) <= 4)
  [
    if current-period != "Free Time!" [
      animate_move 0
      ask links [hide-link]
      ask friend-links [ show-link ]
      set current-period "Free Time!"
    ]
  ])

  ask turtles with [infected? = true and recovering? = false] [
    if (day-of-infection + 7) * 2400 + time-of-infection <= day * 2400 + time [set recovering? true]
  ]
  if (ticks mod 5) = 0 and ((time mod 100) mod 15) = 0 [
    if all? turtles [infected? = false] [ stop ]
    ask turtles with [recovering? = true]
    [
       set virus-check-timer virus-check-timer + 1
       if virus-check-timer >= virus-check-frequency [
        set virus-check-timer 0
      ]
    ]
    if ((time mod 100 ) mod 30 = 0) [spread-virus]
  ]
  display
  do-virus-checks
  tick
end

to animate_move [kind]
  if layout? [
    (ifelse kind = 1 [
      ask turtles [
        facexy scale_xcor scale_ycor
        set move distancexy scale_xcor scale_ycor
      ]
    ]
    kind = 2 [
      ask turtles [
        facexy humanities_xcor humanities_ycor
        set move distancexy humanities_xcor humanities_ycor
      ]
    ]
    kind = 3 [
      ask turtles [
        facexy a_xcor a_ycor
        set move distancexy a_xcor a_ycor
      ]
    ]
    kind = 4 [
      ask turtles [
        facexy b_xcor b_ycor
        set move distancexy b_xcor b_ycor
      ]
    ]
    kind = 5 [
      ask turtles [
        facexy c_xcor c_ycor
        set move distancexy c_xcor c_ycor
      ]
    ]
    [
      ask turtles [
        facexy base_xcor base_ycor
        set move distancexy base_xcor base_ycor
      ]
    ])
    let a 0
    while [a <= 9] [
      ask turtles [ forward (move / 10) ]
      set a (a + 1)
      display
    ]
  ]
end

to setup_shc
  let x 0
  while [x < 10] [
    layout-circle turtles with [scale = (x / 2)] 40
    ask turtles with [scale = (x / 2)] [
      setxy (xcor + item x divide_5) (ycor + (item (x + 1) divide_5))
    ]
    set x x + 2
  ]
  ask turtles [
    set scale_xcor xcor
    set scale_ycor ycor
  ]

  set x 0
  while [x < 6] [
    layout-circle turtles with [humanities = (x / 2)] 75
    ask turtles with [humanities = (x / 2)] [
      setxy (xcor + (item x divide_3)) (ycor + (item (x + 1) divide_3))
    ]
    set x x + 2
  ]
  ask turtles [
    set humanities_xcor xcor
    set humanities_ycor ycor
  ]

  layout-circle turtles with [elective = 0] 50
  ask turtles with [elective = 0] [
    setxy xcor (ycor + 125)
  ]
  layout-circle turtles with [(core-set = 0 and core = 1) or (elective-set = 0 and elective = 3)] 50
  ask turtles with [(core-set = 0 and core = 1) or (elective-set = 0 and elective = 3)] [
    setxy (xcor + 125 * cos 30) (ycor - 125 * sin 30)
  ]
  layout-circle turtles with [(core-set = 0 and core = 2) or (elective-set = 0 and elective = 4)] 50
  ask turtles with [(core-set = 0 and core = 2) or (elective-set = 0 and elective = 4)] [
    setxy (xcor - 125 * cos 30) (ycor - 125 * sin 30)
  ]
  layout-circle turtles with [inactive-set = 0] 40
  ask turtles [
    set a_xcor xcor
    set a_ycor ycor
  ]

  layout-circle turtles with [elective = 5] 60
  ask turtles with [elective = 5] [
    setxy (xcor + (item 0 divide_4)) (ycor + (item 1 divide_4))
  ]
  layout-circle turtles with [elective = 6] 60
  ask turtles with [elective = 6] [
    setxy (xcor + (item 2 divide_4)) (ycor + (item 3 divide_4))
  ]
  layout-circle turtles with [(core-set = 1 and core = 0) or (elective-set = 1 and elective = 1)] 60
  ask turtles with [(core-set = 1 and core = 0) or (elective-set = 1 and elective = 1)] [
    setxy (xcor + (item 4 divide_4)) (ycor + (item 5 divide_4))
    set color white
  ]
  layout-circle turtles with [(core-set = 1 and core = 1) or (elective-set = 1 and elective = 3)] 60
  ask turtles with [(core-set = 1 and core = 1) or (elective-set = 1 and elective = 3)] [
    setxy (xcor + (item 6 divide_4)) (ycor + (item 7 divide_4))
    set color white - 2
  ]

  layout-circle turtles with [inactive-set = 1] 40
  ask turtles [
    set b_xcor xcor
    set b_ycor ycor
  ]

  layout-circle turtles with [(core-set = 2 and core = 0) or (elective-set = 2 and elective = 1)] 40
  ask turtles with [(core-set = 2 and core = 0) or (elective-set = 2 and elective = 1)] [
    setxy (xcor + item 0 divide_5) (ycor + (item 1 divide_5))
  ]
  layout-circle turtles with [(core-set = 2 and core = 2) or (elective-set = 2 and elective = 4)] 40
  ask turtles with [(core-set = 2 and core = 2) or (elective-set = 2 and elective = 4)] [
    setxy (xcor + item 2 divide_5) (ycor + (item 3 divide_5))
  ]
  layout-circle turtles with [elective = 2] 40
  ask turtles with [elective = 2] [
    setxy (xcor + item 4 divide_5) (ycor + (item 5 divide_5))
  ]
  layout-circle turtles with [elective = 7] 40
  ask turtles with [elective = 7] [
    setxy (xcor + item 6 divide_5) (ycor + (item 7 divide_5))
  ]
  layout-circle turtles with [elective = 8] 40
  ask turtles with [elective = 8] [
    setxy (xcor + item 8 divide_5) (ycor + (item 9 divide_5))
  ]
  layout-circle turtles with [inactive-set = 2] 40
  ask turtles [
    set c_xcor xcor
    set c_ycor ycor
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Network Exploration ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; to find all the connected components in the network, their sizes and starting turtles
to find-all-components
  ask turtles [ set explored? false ]
  ;; keep exploring till all turtles get explored
  loop
  [
    ;; pick a node that has not yet been explored
    let start one-of turtles with [ not explored? ]
    if start = nobody [ stop ]
    ;; reset the number of turtles found to 0
    ;; this variable is updated each time we explore an
    ;; unexplored node.
    set component-size 0
    ;; at this stage, we recolor everything to light gray
    ask start [ explore (gray + 2) ]
    ;; the explore procedure updates the component-size variable.
    ;; so check, have we found a new giant component?
    if component-size > giant-component-size
    [
      set giant-component-size component-size
      set giant-start-node start
    ]
  ]
end

;; Finds all turtles reachable from this node (and recolors them)
to explore [new-color]  ;; node procedure
  if explored? [ stop ]
  set explored? true
  set component-size component-size + 1
  ;; color the node
  set color new-color
  ask friend-link-neighbors [ explore new-color ]
end

;; color the giant component red
to color-giant-component
  ask turtles [ set explored? false ]
  ask giant-start-node [ explore blue ]
end

;;;;;;;;;;;;;;;;;;;;;;;
;;; Edge Operations ;;;
;;;;;;;;;;;;;;;;;;;;;;;

to add-specific-edge [input]
  let node1 one-of turtles
  let node2 one-of turtles
  (if-else input = 1 [
    let test [scale] of node1
    if-else any? turtles with [any? my-scale-links = false and scale = test]
    [
      set node2 one-of turtles with [any? my-scale-links = false and scale = test]
    ]
    [
      if-else any? turtles with [color = 7 and scale = test]
      [
        set node2 one-of turtles with [color = 7 and scale = test]
      ]
      [
        set node2 one-of turtles with [scale = test]
      ]
    ]
  ]
  input = 2 [
    let test [humanities] of node1
    if-else any? turtles with [any? my-humanities-links = false and humanities = test]
    [
      set node2 one-of turtles with [any? my-humanities-links = false and humanities = test]
    ]
    [
      if-else any? turtles with [color = 7 and humanities = test]
      [
        set node2 one-of turtles with [color = 7 and humanities = test]
      ]
      [
        set node2 one-of turtles with [humanities = test]
      ]
    ]
  ]
  input = 3 [
    let test [core] of node1
    let my-set [core-set] of node1
    if-else any? turtles with [any? my-core-links = false and core = test and core-set = my-set]
    [
      set node2 one-of turtles with [any? my-core-links = false and core = test and core-set = my-set]
    ]
    [
      if-else any? turtles with [color = 7 and core = test and core-set = my-set]
      [
        set node2 one-of turtles with [color = 7 and core = test and core-set = my-set]
      ]
      [
        set node2 one-of turtles with [core = test and core-set = my-set]
      ]
    ]
  ]
  input = 4 [
    let test [elective] of node1
    let my-set [elective-set] of node1
    if-else any? turtles with [any? my-elective-links = false and elective = test and elective-set = my-set]
    [
      set node2 one-of turtles with [any? my-elective-links = false and elective = test and elective-set = my-set]
    ]
    [
      if-else any? turtles with [color = 7 and elective = test and elective-set = my-set]
      [
        set node2 one-of turtles with [color = 7 and elective = test and elective-set = my-set]
      ]
      [
        set node2 one-of turtles with [elective = test and elective-set = my-set]
      ]
    ]
  ]
  input = 5 [
    let test [math-section] of node1
    if-else any? turtles with [any? my-math-section-links = false and math-section = test]
    [
      set node2 one-of turtles with [any? my-math-section-links = false and math-section = test]
    ]
    [
      if-else any? turtles with [color = 7 and math-section = test]
      [
        set node2 one-of turtles with [color = 7 and math-section = test]
      ]
      [
        set node2 one-of turtles with [math-section = test]
      ]
    ]
  ]
  [
    if-else any? turtles with [any? my-links = false]
    [
      set node2 one-of turtles with [any? my-links = false]
    ]
    [
      if any? turtles with [color = 7]
      [
        set node2 one-of turtles with [color = 7]
      ]
    ]
  ])
;      scale
;  humanities
;  core
;  elective
;  math-section
  ask node1 [
    let a link-neighbors
    (ifelse input = 1 [
      set a scale-link-neighbors
    ]
    [
      set a friend-link-neighbors
    ])
    ifelse member? node2 a or node1 = node2
    ;; if there's already an edge there, then go back
    ;; and pick new turtles
    [ add-specific-edge input ]
    ;; else, go ahead and make it
    [(ifelse input = 1 [
      create-scale-link-with node2
    ]
    input = 2 [
      create-humanities-link-with node2
    ]
    input = 3 [
      create-core-link-with node2
    ]
    input = 4 [
      create-elective-link-with node2
    ]
    input = 5 [
      create-math-section-link-with node2
    ]
    [
      create-friend-link-with node2
    ])]
  ]
end

;;;;;;;;;;;;;;
;;; Layout ;;;
;;;;;;;;;;;;;;
to layout
  if not layout? [ stop ]
  ;; the number 10 here is arbitrary; more repetitions slows down the
  ;; model, but too few gives poor layouts
  repeat 10 [
    do-layout
    if instant? != true [display]  ;; so we get smooth animation
  ]
end

to do-layout
  layout-spring (turtles with [any? link-neighbors]) links 0.5 5 5
end

to highlight
  ask turtles [set color blue]
  ask links [set color white]
  ask turtles with [infected? = true]
  [
    set color red
  ]
  ask turtles with [resistant? = true]
  [
    set color gray
    ask my-links [set color gray - 2]
  ]
  ; if the mouse is in the View, go ahead and highlight
  if mouse-inside? [ do-highlight ]

  ; force updates since we don't use ticks
  display
end
;
to do-highlight
  ; getting the node closest to the mouse
  let min-d min [ distancexy mouse-xcor mouse-ycor ] of turtles
  let node one-of turtles with [count link-neighbors > 0 and distancexy mouse-xcor mouse-ycor = min-d]
;
  if node != nobody [
;    ; highlight the chosen node
    ask node [
      set color white
    ]
;
    let neighbor-nodes [ link-neighbors ] of node
    let direct-links [ my-links with [hidden? = false] ] of node

    ask direct-links [ set color orange ]
    ask node [
      ask direct-links [
        ask other-end [
          set color orange
          ask my-links [
            if [color] of other-end = orange [ set color yellow ]
          ]
        ]
      ]
    ]
  ]
end

to become-infected  ;; turtle procedure
  set infected? true
  set resistant? false
  set recovering? false
  set color red
  set day-of-infection day
  set time-of-infection time
  set total-infected total-infected + 1
end

to become-susceptible  ;; turtle procedure
  set infected? false
  set resistant? false
  set color blue
end

to become-resistant  ;; turtle procedure
  set infected? false
  set resistant? true
  set color gray
  ask my-links [ set color gray - 2 ]
end

to spread-virus
  ask turtles with [infected? = true] [
    ask my-links with [hidden? = false] [
      if [resistant?] of other-end = false and [infected?] of other-end = false [
        ask other-end [
          let b virus-spread-chance
          if vaccinated? [ set b b * vaccination-infection-multiplier]
          if random-float 100 < b [
            become-infected
          ]
        ]
      ]
    ]
  ]
end

to do-virus-checks
  ask turtles with [infected? = true and virus-check-timer = 0]
  [
    let a recovery-chance
    let b gain-resistance-chance
    if vaccinated? [
      set a a * vaccination-recovery-multiplier
      set b b * vaccination-resistance-multiplier
    ]
    if random 100 < a
    [
      set recovering? false
      ifelse random 100 < b
        [ become-resistant ]
        [ become-susceptible ]
    ]
  ]
end

to looper
  loop [if-else any? turtles with [infected? = true] [ go2 ] [stop]]
end

to-report infected-count
  report total-infected
end


; Copyright 2005 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
463
36
876
450
-1
-1
1.01
1
10
1
1
1
0
0
0
1
-200
200
-200
200
0
0
1
ticks
30.0

BUTTON
47
38
127
71
setup
setup
NIL
1
T
OBSERVER
NIL
1
NIL
NIL
1

SLIDER
47
86
233
119
num-nodes
num-nodes
2
500
100.0
1
1
NIL
HORIZONTAL

BUTTON
231
38
324
71
start infection
go2\n
T
1
T
OBSERVER
NIL
3
NIL
NIL
0

BUTTON
294
86
388
119
Inspect Link
if done? = true [highlight]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
46
135
234
168
initial-outbreak-size
initial-outbreak-size
1
15
4.0
1
1
NIL
HORIZONTAL

SLIDER
252
135
435
168
virus-spread-chance
virus-spread-chance
0
10
3.0
0.1
1
%
HORIZONTAL

SLIDER
46
175
235
208
virus-check-frequency
virus-check-frequency
4
20
8.0
4
1
ticks
HORIZONTAL

SLIDER
252
177
436
210
recovery-chance
recovery-chance
0
10
9.5
0.1
1
%
HORIZONTAL

SLIDER
46
218
235
251
gain-resistance-chance
gain-resistance-chance
0
100
50.0
1
1
%
HORIZONTAL

BUTTON
138
38
220
71
instant-go-1
let a 0\nif done? = true [stop]\nif-else any? turtles with [color = 7] [\n  instant-go\n]\n[ set a 1 ]\nif a = 1 and done? = false[\n  if layout? [\n    repeat 200 [\n      layout-spring (turtles with [any? friend-link-neighbors]) links 0.3 150 200\n      ;layout-tutte (turtles with [count link-neighbors > 1]) links 200+\n    ]\n  ]\n  \n  ask turtles [\n    set base_xcor xcor\n    set base_ycor ycor\n  ]\n  \n  ask n-of (initial-outbreak-size) turtles [ become-infected ]\n;  ask n-of 5 turtles with [infected? = false] [become-resistant]\n  set done? true\n  stop\n]
T
1
T
OBSERVER
NIL
2
NIL
NIL
1

OUTPUT
46
377
312
473
25

SLIDER
252
219
437
252
vaccinated-percentage
vaccinated-percentage
0
100
30.0
1
1
%
HORIZONTAL

SLIDER
45
262
236
295
vaccination-infection-multiplier
vaccination-infection-multiplier
0
0.9
0.3
0.1
1
NIL
HORIZONTAL

SLIDER
45
306
237
339
vaccination-resistance-multiplier
vaccination-resistance-multiplier
1.1
2
1.7
0.1
1
NIL
HORIZONTAL

SLIDER
251
263
438
296
vaccination-recovery-multiplier
vaccination-recovery-multiplier
1.1
2
1.7
0.1
1
NIL
HORIZONTAL

PLOT
906
201
1216
363
Cumulative Statistics
Day
# of People
0.0
21.0
0.0
150.0
true
true
"" ""
PENS
"Infected" 1.0 0 -2674135 true "" "plotxy (day + time / 2400) count turtles with [infected? = true]"
"Susceptible" 1.0 0 -13345367 true "" "plotxy (day + time / 2400) count turtles with [infected? = false and resistant? = false]"
"Resistant" 1.0 0 -7500403 true "" "plotxy (day + time / 2400) count turtles with [resistant? = true]"
"Day 7" 1.0 0 -2064490 true "plot-pen-up\nplotxy 7 0\nplot-pen-down\nplotxy 7 150" ""
"Day 14" 1.0 0 -2064490 true "plot-pen-up\nplotxy 14 0\nplot-pen-down\nplotxy 14 150" ""
"Total" 1.0 0 -8053223 true "" ""

PLOT
906
36
1216
198
Daily Statistics
Time
# of People
730.0
1730.0
0.0
90.0
false
true
"" "if time = 730 [clear-plot]"
PENS
"Infected" 1.0 0 -2674135 true "" "plotxy time count turtles with [infected? = true]"
"Susceptible" 1.0 0 -13345367 true "" "plotxy time count turtles with [infected? = false and resistant? = false]"
"Resistant" 1.0 0 -7500403 true "" "plotxy time count turtles with [resistant? = true]"

BUTTON
334
38
435
71
NIL
looper
NIL
1
T
OBSERVER
NIL
4
NIL
NIL
1

PLOT
906
367
1216
530
Total Infection Count
Day
# of People
0.0
21.0
0.0
150.0
true
true
"" ""
PENS
"Infected  " 1.0 0 -8053223 true "" "plotxy (day + time / 2400) total-infected"

MONITOR
576
466
764
511
incidence rate per 100 person-days
(total-infected * 100)/(num-nodes * day)
2
1
11

@#$#@#$#@
## WHAT IS IT?

In a network, a "component" is a group of nodes (people) that are all connected to each other, directly or indirectly.  So if a network has a "giant component", that means almost every node is reachable from almost every other.  This model shows how quickly a giant component arises if you grow a random network.

## HOW IT WORKS

Initially we have nodes but no connections (edges) between them. At each step, we pick two nodes at random which were not directly connected before and add an edge between them.  All possible connections between them have exactly the same probability of occurring.

As the model runs, small chain-like "components" are formed, where the members in each component are either directly or indirectly connected to each other.  If an edge is created between nodes from two different components, then those two components merge into one. The component with the most members at any given point in time is the "giant" component and it is colored red.  (If there is a tie for largest, we pick a random component to color.)

## HOW TO USE IT

The NUM-NODES slider controls the size of the network.  Choose a size and press SETUP.

Pressing the GO ONCE button adds one new edge to the network.  To repeatedly add edges, press GO.

As the model runs, the nodes and edges try to position themselves in a layout that makes the structure of the network easy to see.  Layout makes the model run slower, though.  To get results faster, turn off the LAYOUT? switch.

The REDO LAYOUT button runs the layout-step procedure continuously to improve the layout of the network.

A monitor shows the current size of the giant component, and the plot shows how the giant component's size changes over time.

## THINGS TO NOTICE

The y-axis of the plot shows the fraction of all nodes that are included in the giant component.  The x-axis shows the average number of connections per node. The vertical line on the plot shows where the average number of connections per node equals 1.  What happens to the rate of growth of the giant component at this point?

The model demonstrates one of the early proofs of random graph theory by the mathematicians Paul Erdos and Alfred Renyi (1959).  They showed that the largest connected component of a network formed by randomly connecting two existing nodes per time step, rapidly grows after the average number of connections per node equals 1. In other words, the average number of connections has a "critical point" where the network undergoes a "phase transition" from a rather unconnected world of a bunch of small, fragmented components, to a world where most nodes belong to the same connected component.

## THINGS TO TRY

Let the model run until the end.  Does the "giant component" live up to its name?

Run the model again, this time slowly, a step at a time.  Watch how the components grow. What is happening when the plot is steepest?

Run it with a small number of nodes (like 10) and watch the plot.  How does it differ from the plot you get when you run it with a large number of nodes (like 300)?  If you do multiple runs with the same number of nodes, how much does the shape of the plot vary from run to run?  You can turn off the LAYOUT? switch to get results faster.

## EXTENDING THE MODEL

Right now the probability of any two nodes getting connected to each other is the same. Can you think of ways to make some nodes more attractive to connect to than others?  How would that impact the formation of the giant component?

When creating new links in the `add-edge` procedure, you might be wondering why we don't do something like this:

    ask one-of turtles [
      create-link-with one-of other turtles with [ not link-neighbor? myself ]
    ]

Imagine that we have one node in the network that is already connected to most of the other nodes. In the original version of `add-edge`, if that node is picked as one of the two nodes between which we try to create an edge, it will probably get rejected because it is likely that it's already linked with the other node picked. In this alternate version of `add-edge`, however, we tell NetLogo to explicitly go looking for a node that is not already connected to the first one (even if there are very few of those). That makes a big difference. Try it and see how it impacts the formation of the giant component.

## NETWORK CONCEPTS

Identification of the connected components is done using a standard search algorithm called "depth first search."  "Depth first" means that the algorithm first goes deep into a branch of connections, tracing them out all the way to the end.  For a given node it explores its neighbor's neighbors (and then their neighbors, etc) before moving on to its own next neighbor.  The algorithm is recursive so eventually all reachable nodes from a particular starting node will be explored.  Since we need to find every reachable node, and since it doesn't matter what order we find them in, another algorithm such as "breadth first search" would have worked equally well.  We chose depth first search because it is the simplest to code.

The position of the nodes is determined by the "spring" method, which is further described in the Preferential Attachment model.

## NETLOGO FEATURES

Nodes are turtle agents and edges are link agents. The `layout-spring` primitive places the nodes, as if the edges are springs and the nodes are repelling each other.

Though it is not used in this model, there exists a network extension for NetLogo that you can download at: https://github.com/NetLogo/NW-Extension.

## RELATED MODELS

See other models in the Networks section of the Models Library, such as Preferential Attachment.

See also Network Example, in the Code Examples section.

There is also a version of this model using the (NW extension)[https://github.com/NetLogo/NW-Extension] in the `demo` folder of the extension.

## CREDITS AND REFERENCES

This model is adapted from:
Duncan J. Watts. Six Degrees: The Science of a Connected Age (W.W. Norton & Company, New York, 2003), pages 43-47.

The work Watts describes was originally published in:
P. Erdos and A. Renyi. On random graphs. Publ. Math. Debrecen, 6:290-297, 1959.

This paper has some additional analysis:
S. Janson, D.E. Knuth, T. Luczak, and B. Pittel. The birth of the giant component. Random Structures & Algorithms 4, 3 (1993), pages 233-358.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (2005).  NetLogo Giant Component model.  http://ccl.northwestern.edu/netlogo/models/GiantComponent.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2005 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2005 -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
