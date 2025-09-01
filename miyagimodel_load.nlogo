extensions[gis]

globals[
  world-size
  road-dataset
  elev-dataset
  river-dataset
  bledge-dataset
  evac-dataset
  popu-dataset
  musen-dataset
  alist ;;use for dijkstra
  tlist ;;for info
  guideinfolist ;;for info of guide
  asklist ;;asking info
  dislist
  dislisthv
  dislistgv
  dislistmusen
  agentnum ;;the number of people now
  initialnum ;;the number of peoplein  initial time
  successnum
  rednum
  bluenum
  safenum
  evactime
  timeunit
  adjacentmatrix
  evaccor  ;;not need
  evac-patches
  deadevac-patches
  musen-patches
  musen-info-patches
  tall-patches
  tsunami-patches
  fields
  guides
  sizerate
  numberdivide
  musennum
  latestnum  ;;the index of latest evacuation route list
  evacstart
  wirelessradius
  loaded?
  startagentnum
  finishtime5
  finishtime10
  finishtime20
  finishtime30
  finishtime45
  finishtime60
  finishtimeany
]

turtles-own[
  moved?
  hasinfo?
  peoplenum
  moveway  ;;0:random 1:moveforward 2:together 3:move to higher
  nextmove
  nextmovetime
  agent-type  ;;0:evac,1:yuudouin
  isevac?
  guidetime
  waitmove
  movespeedinv
  previous_x
  previous_y
  talkfreq
  routenum ;;the index of evacuation route list that agent have
  hasmobile?
  init-evac
  init-evac-time
  reccnt
  isride?
  movingtime
  fast
]
patches-own[
  Isroad
  elevation ;;dijkstra distance moore
  elevation4 ;;dijkstra distance 4
  altielev
  exit ;;evacuation patch
  ismusen
  path
  isvisit? ;;use for dijkstra
  recinfotime
  museninfotime
  guideinfotime
  recasktime
  p_ask
  p_rec
  keepinfo ;;time of information remind
  keepinfob
  alti
  riv
  blg
  blg2
  nami
  popu
  popu2
  popu3
  terrain-type ;;0:field 1:buildings 2:river
  arealabel  ;; id of nearest evacuation center
  capa  ;;capacity
  musen-prob
  musenarea?
  infolevel
  tsunamitime
  tsunamicome?
]

__includes [
  "evacu_fanction.nls"
  "miyagimovement.nls"
  "shortest_algorithm.nls"
  "miyagiactions.nls"
  "fileoperation.nls"
  "miyagiparam.nls"
]

to loopsimulation
  let loopcnt 2
  while [loopcnt < 4][
    setup
    while [timeunit <= 3600 + 2400]
    [
      go
      set timeunit timeunit + 1
      let hours floor (timeunit / 3600)
      let minutes floor ((timeunit mod 3600) / 60)
      let seconds timeunit mod 60
      let zerominutes "00"
      let zeroseconds "00"
      ifelse minutes < 10 [set zerominutes (word "0" minutes)][set zerominutes (word minutes)]
      ifelse seconds < 10 [set zeroseconds (word "0" seconds)][set zeroseconds (word seconds)]
      set evactime (word (hours) ":" (zerominutes) ":" (zeroseconds))


      if (timeunit mod 100) = 0
      [
      statisticsl hours minutes loopcnt
      if (timeunit mod 300) = 0 [
        statisticsl2 hours minutes loopcnt
        set startagentnum 0
      ]
      ]
    ]

      print 100 * successnum / initialnum
      show timer
      statistics3l loopcnt
      set loopcnt loopcnt + 1
  ]
end

to setup

  ca
  reset-ticks
  modo 0 ;;0:debug, 1:release
  ;;resize-world 0 1620 0 1080 ;;10km/1620=6.2m a patch is (6.2m)^2 3:2
  resize-world 0 (1620 * 1 - 1) 0 (1080 * 1 - 1) ;;10km/2430=4.1m
  reset-timer
  load_maps
  ;;set_evac
  show timer
  ;;elevdijkstra
  dijkstra
  dijkstra4
  distancelist 10
  create_people
  set_musen_information
  set timeunit 0

  set-patch-size 0.015
  show timer
  reset-timer
  print "You can start now"
end

to set_map
  ca
  reset-ticks
  resize-world 0 1620 0 1080

  load_maps
  ;;set_evac
  dijkstra
  dijkstra4
  ;;evacinfo
  set timeunit 0
  set-patch-size 0.015
  print "You can start now"
end

to set_agents
  reset-ticks
  create_people
end

to clear-turtle
  ct
end

to go
  ;;if count turtles = 0 [stop]
  ;;if timeunit >= 3600 + 2400 [
  ;;  print 100 * successnum / initialnum
  ;;  show timer
  ;;  statistics3
  ;;  stop
 ;; ]
  ;;ask patches with [exit = 1] [ask turtles-here[if agent-type = 0 [die]]]
  ask evac-patches [
    ask turtles-here [if agent-type = 0 [
      set successnum successnum + peoplenum
      set capa capa - peoplenum  ;;capa over
      ifelse movingtime <= 300 [set finishtime5 finishtime5 + peoplenum][
        ifelse movingtime <= 600 [set finishtime10 finishtime10 + peoplenum][
          ifelse movingtime <= 1200 [set finishtime20 finishtime20 + peoplenum][
            ifelse movingtime <= 1800 [set finishtime30 finishtime30 + peoplenum][
              ifelse movingtime <= 2700 [set finishtime45 finishtime45 + peoplenum][
                ifelse movingtime <= 3600 [set finishtime60 finishtime60 + peoplenum][
                  set finishtimeany finishtimeany + peoplenum]
              ]
            ]
          ]
        ]
      ]
      die
    ]]
  ]

  ask turtles
  [
    if agent-type = 0
    [
      if [tsunamitime] of patch-here + 2400 <= timeunit + runaway + 5 and [tsunamitime] of patch-here + 2400 >= timeunit + runaway - 5 and init-evac = 5 or [tsunamitime] of patch-here + 2400 <= timeunit + 605 and [tsunamitime] of patch-here + 2400 >= timeunit + 595
      [
        set init-evac-time 0
        ;;set isevac? true
        set hasinfo? true
        if [altielev] of patch-here < item latestnum [elevation] of patch-here
        [set moveway 3]
        ;;set moveway 3
        setspeedinv
        set waitmove 0
      ]

    ]
    ifelse [alti] of patch-here > 165 and agent-type = 0
    [
     set successnum successnum + peoplenum
      let pn peoplenum
      ask patch-here [ set capa capa - pn]
      ifelse movingtime <= 300 [set finishtime5 finishtime5 + peoplenum][
        ifelse movingtime <= 600 [set finishtime10 finishtime10 + peoplenum][
          ifelse movingtime <= 1200 [set finishtime20 finishtime20 + peoplenum][
            ifelse movingtime <= 1800 [set finishtime30 finishtime30 + peoplenum][
              ifelse movingtime <= 2700 [set finishtime45 finishtime45 + peoplenum][
                ifelse movingtime <= 3600 [set finishtime60 finishtime60 + peoplenum][
                  set finishtimeany finishtimeany + peoplenum]
              ]
            ]
          ]
        ]
      ]
     die
    ]
    [if floor ([tsunamitime] of patch-here * 1.5) + 2400 <= timeunit and [tsunamitime] of patch-here <= 1200
    [die]
    ]
  ]

  ask deadevac-patches [
   ask turtles-here [if agent-type = 0[
     set routenum latestnum
    ]]
  ]
  ask evac-patches [
  if capa <= 0 [
      disevac arealabel
  ]]

  set tlist []
  set asklist []
  set guideinfolist []

  ask turtles with [agent-type = 0 and isevac? = false]
  [if init-evac-time <= timeunit [
    set isevac? true
    setspeedinv
    set waitmove 0
    set startagentnum startagentnum + peoplenum
  ]]

  ask turtles with [hasinfo? = true and agent-type = 0 ][
    if isevac? = true [
    if waitmove <= 0
    [
      while [waitmove <= 0][
        set previous_x xcor
        set previous_y ycor
          ;;ifelse moveway = 3 [movetotaller][infomove]
         ifelse [altielev] of patch-here < item latestnum [elevation] of patch-here or moveway = 3
          [movetotaller][infomove]
          let distancefromprevious max list 1 (distancexy previous_x previous_y)
        set waitmove waitmove + movespeedinv * distancefromprevious
        if distancefromprevious < 0.5 [set waitmove 0.001]
      ]
      ;;give_info 4
      receive_asking
    ]
  ]]


  ;;agents that dont have info moves randomly
  ask turtles with [hasinfo? = false and agent-type = 0][
    if isevac? = true [
    if waitmove <= 0 [
        while [waitmove <= 0][
         set previous_x xcor
         set previous_y ycor
         movetoguide
         if moved? = false
          [
            ifelse moveway = 0 [randommove2]
            [ifelse moveway = 1 [moveforward 800][
              ifelse moveway = 2 [movetogether]
              [movetotaller]
              ]
            ]
          ]

         let distancefromprevious max list 1 (distancexy previous_x previous_y)
         set waitmove waitmove + movespeedinv * distancefromprevious
         if distancefromprevious < 0.5 [set waitmove 0.001]
       ]
       ask_info
    ]
  ]]

  ask_information
  if timeunit >= 300[guide_action]
  send_information
  receive_information

  ask turtles with [isevac? = true and agent-type = 0]
  [
    setspeedinv
    set waitmove waitmove - 1
    set movingtime movingtime + 1
  ]
  if timeunit >= 2399 and timeunit <= 2400 + 1200 [
  ask tsunami-patches with [timeunit = floor (tsunamitime * 1.5) + 2400][
      set pcolor blue
      if exit = 1
      [
        disevac arealabel
      ]
    ]
  ]
  set rednum 0
  set bluenum 0
  set safenum 0
  ask turtles with [agent-type = 0]
  [ifelse hasinfo? = true [set rednum rednum + peoplenum]
    [set bluenum bluenum + peoplenum]
  ]
  ask guides [set safenum (safenum + peoplenum - 1)]

  set timeunit timeunit + 1
  let hours floor (timeunit / 3600)
  let minutes floor ((timeunit mod 3600) / 60)
  let seconds timeunit mod 60
  let zerominutes "00"
  let zeroseconds "00"
  ifelse minutes < 10 [set zerominutes (word "0" minutes)][set zerominutes (word minutes)]
  ifelse seconds < 10 [set zeroseconds (word "0" seconds)][set zeroseconds (word seconds)]
  set evactime (word (hours) ":" (zerominutes) ":" (zeroseconds))


  ;;if (timeunit mod 100) = 0
 ;; [
  ;;  statistics hours minutes
  ;;  if (timeunit mod 300) = 0 [
  ;;    statistics2 hours minutes
  ;;    set startagentnum 0
  ;;  ]
  ;;]

  tick
end



to debug
  ;;ask patches [
  ;;  let labelcolor [gray pink magenta cyan violet]
  ;;  set pcolor (item arealabel labelcolor)
  ;;]
  ;;set musen-patches patches with [ismusen = 1]
  ;;ask turtles with [agent-type = 0][print routenum]
  ;;print initialnum
  ask patches with [alti > 165]
  [set pcolor cyan]
end

to disapper
  disevac 0
end

to show_matrix
  print "---------------------"
  foreach adjacentmatrix [
   row -> show row
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
248
10
1822
1063
-1
-1
0.015
1
10
1
1
1
0
0
0
1
0
1619
0
1079
0
0
1
ticks
30.0

BUTTON
12
12
75
45
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
12
52
75
85
Run
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
80
12
154
45
set map
set_map
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
157
12
244
45
set agents
set_agents
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
12
91
104
124
clear turtle
clear-turtle
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
14
229
214
379
number of agents
time
turtle
0.0
100.0
0.0
500.0
true
false
"" ""
PENS
"hasinfo" 1.0 0 -2674135 true "" "plot rednum"
"not hasinfo" 1.0 0 -13345367 true "" "plot bluenum"

MONITOR
13
174
95
219
NIL
agentnum
17
1
11

BUTTON
12
131
78
164
debug
debug
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
119
174
212
219
evacuation-time
evactime
17
1
11

BUTTON
88
131
169
164
NIL
disapper
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
81
52
144
85
save
save_to_file
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
150
52
213
85
load
load_from_file
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
14
402
214
552
success rate
time
rate
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot 100 * successnum / initialnum"

MONITOR
18
565
95
610
success rate
100 * successnum / initialnum
17
1
11

SLIDER
18
619
190
652
agentweight
agentweight
1
60
30.0
1
1
NIL
HORIZONTAL

SLIDER
19
675
191
708
runaway
runaway
0
2400
1200.0
30
1
秒
HORIZONTAL

BUTTON
120
92
236
125
NIL
loopsimulation
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
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
