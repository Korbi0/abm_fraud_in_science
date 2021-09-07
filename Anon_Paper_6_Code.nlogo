;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                 initialisation                      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

globals [test-times total-tests test-number datalist success s]

extensions [ nw csv ]

turtles-own [acc1
 acc0
share-group]

science-own [y1 y0] ; number of correct diagnoses for each treatment

breed [ policy pol-maker]
breed [ science scientist]
breed [ propaganda prop]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                 core functions                      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  ca
  reset-ticks
  create-network
  set test-times 10
  set test-number 0
  set total-tests test-times
  set datalist []
  ask policy [trust]
  set s 0

end

to go
  set success 0
  set test-number (test-number + 1)
  set total-tests (test-times * test-number)
  experiment
  communicate

  let outs []
  set outs lput total-tests outs

  ask policy[
    set outs lput (precision acc0 2) outs
    set outs lput (precision acc1 2) outs]
  if item 2 outs > item 1 outs [set success (success + 0.5)] ;success if policy 1 finds treatment 1 strictly better
  if item 4 outs > item 3 outs [set success (success + 0.5)] ;success if policy 2 finds treatment 1 better
  set outs lput success outs
print success
  set s s + success

  set datalist lput outs datalist

  tick
end

to data
  repeat runs [
    go]
   print s / 10
  print "done"
  csv:to-file "myfile.csv" datalist
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                      network                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to create-network
ifelse propagandist [
  if network = "preferential-attachment" [
    create-network-pref-wp]

  if network = "complete" [
    create-turtles (num-agents - 1)
    create-network-complete-wp]

  if network = "wheel" [
    create-network-wheel-wp ]

  ; make some non-propaganist agents policy makers
  ask n-of 2 turtles with [breed != propaganda] [
      set breed policy
      set color white
      set shape "face neutral"]

  ; make remaining (non-propaganist and non-policy) agents scientists
  ask turtles with [ breed != policy and breed != propaganda  ] [
      set breed science
      set color red
      set shape "face happy"]]
  [ ; if no propagandist
  if network = "preferential-attachment" [
    create-network-pref]

  if network = "complete" [
    create-turtles num-agents
    create-network-complete]

  if network = "wheel" [
    create-network-wheel]

  ; make some agents policy makers
  ask turtle 2  [ ; science breed only set for centre of wheel
      set breed policy
      set color white
      set shape "face neutral"]

      ask turtle (num-agents / 2)  [ ; science breed only set for centre of wheel
      set breed policy
      set color white
      set shape "face neutral"]

  ; make remaining agents scientists
  ask turtles with [ breed != policy and breed != propaganda  ] [
      set breed science
      set color red
      set shape "face happy"]]
end

to create-network-pref
    nw:generate-preferential-attachment turtles links num-agents 1 [
      setxy random-xcor random-ycor]

  ; this makes it look pretty
  repeat 30 [ layout-spring turtles links 0.2 5 1 ]
end

to create-network-complete
  ask turtles [
    create-links-with other turtles]

   layout-circle turtles 15
end

to create-network-wheel
  create-turtles (num-agents - 1)
  let turtle-list sort turtles ; numbers each turtle
  ; adds link to "next" turtle, taken from Dunja
  let previous-turtle 0
    foreach turtle-list [ [cur-turtle] ->
      ask cur-turtle [
        ifelse previous-turtle != 0 [
          create-link-with previous-turtle
          set previous-turtle self][
          create-link-with last turtle-list
          set previous-turtle self] ] ]

  layout-circle turtle-list 15

  ; last/centre turtle is linked to all and is made scientist so it is not policy maker
  create-science 1 [
    create-links-with other turtles
    set color red
    set shape "face happy"]
end

to create-network-pref-wp
    nw:generate-preferential-attachment turtles links (num-agents - 1) 1 [
      setxy random-xcor random-ycor]

    create-propaganda 1 [
    create-links-with other turtles
    set color blue
    set shape "face sad"]
  repeat 30 [ layout-spring turtles links 0.2 5 1 ]
end

to create-network-complete-wp
  ask turtles [
    create-links-with other turtles]

   layout-circle turtles 15

create-propaganda 1 [
    create-links-with other turtles
    set color blue
    set shape "face sad"]
end

to create-network-wheel-wp
  create-turtles (num-agents - 1)
  let turtle-list sort turtles ; numbers each turtle
  ; adds link to "next" turtle, taken from Dunja
  let previous-turtle 0
    foreach turtle-list [ [cur-turtle] ->
      ask cur-turtle [
        ifelse previous-turtle != 0 [
          create-link-with previous-turtle
          set previous-turtle self][
          create-link-with last turtle-list
          set previous-turtle self] ] ]

  layout-circle turtle-list 15

  ; last/centre turtle is linked to all and is made propandist
  create-propaganda 1 [
    create-links-with other turtles
    set color blue
    set shape "face sad"]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                 communication                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;who to communicate with
to trust
   if norm = "Reidian"[
    trust-reid]
  if norm = "majoritarian Reidian"[
    trust-majreid]
  if norm = "e-truster"[
    trust-expert]
  if norm = "majoritarian e-truster"[
    trust-majexpert]
end

;random neighbour
to trust-reid
 ask policy[
    set share-group (one-of (link-neighbors))
    ask share-group [
      set color yellow] ]
end

;all neighbours
to trust-majreid
 ask policy[
    set share-group in-link-neighbors
    ask share-group [
      set color yellow]]
end

; random scientist or propaganda
to trust-expert
 ask policy[
    set share-group (one-of (in-link-neighbors with [breed != policy]))
   ask share-group [
      set color yellow]]
end

;all scientist and propaganda
to trust-majexpert
  ask policy[
    set share-group (in-link-neighbors with [breed != policy])
    ask share-group [
    set color yellow]]
end

;how to update
to communicate
  if norm = "Reidian"[
    comm-one]
  if norm = "majoritarian Reidian"[
    comm-maj]
  if norm = "e-truster"[
    comm-one]
  if norm = "majoritarian e-truster"[
    comm-maj]
end

;non majoritarian, single
to comm-one
  let cred0 []
  let cred1 []
  ask policy[
    ask share-group [
      set cred0 lput acc0 cred0
      set cred1 lput acc1 cred1]]
  ask policy [
  set acc0 (one-of cred0)
  set acc1 (one-of cred1)]
end

;majoritarian, average
to comm-maj
  let cred0 []
  let cred1 []
  ask policy[
    ask share-group [
      set cred0 lput acc0 cred0
      set cred1 lput acc1 cred1]
  set acc0 (mean cred0)
  set acc1 (mean cred1)]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                    experiment                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to experiment
ask science [
    ;performs test 1
    repeat test-times[
  ifelse random 99 < prevalence  [ ;has condition
      ifelse random 99 < SN_1
      [set y1 (y1 + 1)] ;tru-pos
      [; fls-neg
      ]]
  ;doesn't have condition
  [ifelse random 99 < SP_1
        [set y1 (y1 + 1)] ;tru-neg
      [;fls-pos
    ]]]

    ;performs test0
  repeat test-times[
  ifelse random 99 < prevalence  [ ;has condition
      ifelse random 99 < SN_0
      [set y0 (y0 + 1)] ;tru-pos
      [;fls-neg
      ]]
  ;doesn't have condition
  [ifelse random 99 < SP_0
      [set y0 (y0 + 1)] ;tru-neg
      [; fls-pos
    ]]]
     ; accuracy_n = correct diagnonses / tests run for treatment_n
   set acc0  (y0 / total-tests)
   set acc1 (y1 / total-tests)]

  ;collect the accuracy reports of all scientists for propogandist
  let cred0 []
  let cred1 []
  ask science[
  set cred0 lput acc0 cred0
 set cred1 lput acc1 cred1 ]

    ;propagandist reports best accuracy found for treatment0 and worst accuracy for treatment1
  ask propaganda[
    set acc0 max cred0
    set acc1 min cred1]
end


;  let res []
;
;  ask turtles [
;    set res lput (precision acc0 2) res
;    set res fput (precision acc1 2) res]
;
;  set datalist fput res datalist
@#$#@#$#@
GRAPHICS-WINDOW
370
10
807
448
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

SLIDER
16
23
184
56
num-agents
num-agents
2
100
0.0
1
1
NIL
HORIZONTAL

BUTTON
16
237
82
271
NIL
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
124
237
188
271
NIL
data
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
5
165
178
210
network
network
"random" "preferential-attachment" "complete" "wheel"
2

CHOOSER
5
110
180
155
norm
norm
"Reidian" "majoritarian Reidian" "e-truster" "majoritarian e-truster"
3

SLIDER
15
65
187
98
prevalence
prevalence
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
190
175
362
208
SN_1
SN_1
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
190
215
362
248
SP_1
SP_1
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
190
105
362
138
SN_0
SN_0
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
190
140
362
173
SP_0
SP_0
0
100
0.0
1
1
NIL
HORIZONTAL

SWITCH
215
25
342
58
propagandist
propagandist
1
1
-1000

SLIDER
190
65
362
98
runs
runs
0
100
0.0
10
1
NIL
HORIZONTAL

PLOT
55
355
255
505
plot 1
NIL
NIL
0.0
10.0
-1.0
2.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot success"

@#$#@#$#@
## WHAT IS IT?

For developed 

This model looks at the correction of false information in social networks, with variants for different media environments. Information spreads within the network via both broadcast and social influence.  Some nodes, called "researchers" which represent either people or organizations, are more resistant to false information and do not adopt it. Since time is required to notice and correct false information, researcher nodes initially have no effect on the spread or correction of information, but exert influence after a user-modifiable delay. 

Diffusion of information in this model is based on the Bass model. Three different variants are offered for handling of the broadcast influence component: uniform and affected by node consensus, biased with an irregular shape, and biased with two large regions. Initially broadcast influence only affects adoption of false information. After research-delay ticks have passed, broadcast influence affects both adoption and correction, the effect in either case depends on the broadcast variant chosen. 

Changing views (adoption/correction) can occur for regular nodes, but resistance to belief modification is modeled by reducing the likelihood of changing belief after either adoption or correction. The model can be run with or without re-adoption allowed after correction.

Different network structures can also be investigated (random, preferential attachment, Watts-Strogatz small world).  

## HOW IT WORKS

The SETUP procedure creates a network of the type selected in "network-type" and assigns patches properties used to simulate the media environment, if either "media bias" variant is chosen.  Nodes in the network are then assigned to be "regular" or "researcher." The fraction of nodes selected as "researchers" can be modified in the interface. Researchers are resistant to adopting false information, but there is a delay before their influence is included in the social network. The length of this delay can be modified with the research-delay slider. The setup procedure also initializes global variables.

The GO procedure recalculates global variables and handles the spread of information through the network. Once the research-delay has expired, nodes can correct their information.  Nodes that have already adopted the false information can correct it but this is more difficult than correcting information prior to adoption.  The degree to which views are likely to change can be modified with the "openness-to-change" slider. For regular nodes, both adoption and correction are open to change. (Researchers do not adopt.) The model can be run with regular nodes either permitted or restricted from re-adopting once corrected.  

The RESET procedure resets the adoption pattern but leaves the network links and node types in place.


## HOW TO USE IT

###Inputs

**Prior to starting the model, set the variant choice, number of agents, network type and parameters. The parameters at the top of the interface are:**

VARIANT: The media environment can be one of:

* uniform: uniform broadcast influence, after research-delay this is proportional to the percent of nodes that have adopted or corrected information
* irregular media bias: broadcast media exerts greater influence toward adoption or correction, based on patch voting and represented by patch color. (green: correction, orange: adoption)
* media bias - block: as with "irregular media bias," but patch y location determines setting.

INITIAL-GREEN-PCT: Sets the percetage of patches which are green (media bias toward correction) in the media bias variants.  In the irregular version, this is the intial percent but is modified by voting.

NETWORK-TYPE:  Network types can be Preferential Attachment, Random, or Small Worlds.  Small worlds uses the Watts-Strogatz model.  All networks use the nw extension.

NETWORK-DENSITY: This slider is relevant only for Random networks and is the connection probability for each node.  (See nw:generate-random)

NEIGHBORHOOD-SIZE: Used in the small worlds (Watts-Strogatz) network and governs the number of initial links for each node. (See nw:generate-watts-strogatz)

REWIRE-PROBABILITY: Used in small worlds (Watts-Strogatz) network and is probability of each link rewiring (See nw:generate-watts-strogatz)

**The next set of sliders govern how many nodes are in the network and the fraction which are researchers.  Don't change these if resetting adoption and running on the same network.**

NUM-AGENTS: This slider sets the number of nodes in the network.  

RESEARCHER-FRAC: Sets the fraction of NUM-AGENTS which are researchers.  These will be randomly selected among the nodes. They will be represented by circles.

**The lower set of parameters can change between runs on the same network.**

RE-ADOPTION: Choose whether to allow regular nodes to readopt after correction.

SOCIAL-INFLUENCE: Degree of influence link neighbors have on individual adoption or correction.

BROADCAST-INFLUENCE: Degree of influence broadcast media have on individual adoption or correction.  

RESEARCH-DELAY: Sets the number of ticks before correction begins to counter the adoption of false information.  

OPENNESS-TO-CHANGE: This slider sets how likely a node is to changing views once either adopted? or corrected? are true.  A value of 1.0 indicates that nodes are open to change, a value of 0 indicates high resistance to view modification. In this version, regular nodes have an individual "change" property which are assigned in an exponential distribution using "openness-to-change" as the mean. 

STOP-TICKS: This sets a back-up stop condition for the model.  The model will also stop if all nodes are corrected.  Since researcher nodes do not adopt, the model does not stop when all nodes have adopted.

SETUP:  Sets up the network and node breeds and initializes global variables.

GO: Runs the model adoption and correction and updates global variables.

RESET: Keeps the network, media environment, and node breeds the same, but resets adopted? and corrected? (other than for researchers).

###Outputs

%ADOPTED: Plots the percent of the nodes who have adopted over time. 

CORRECTION BASIS: Plots the percent of regular nodes who have corrected based on broadcast influence and based on social influence.

PEAK % ADOPTED: Percent of nodes at peak adoption

TICKS TO PEAK ADOPTION: Ticks at which peak adoption first occurs

TICKS TO 50% OFF PEAK: Ticks until the adoption rate drops below 50% of its peak

## AGENTS 

There are two breeds of turtle, or node, in this model, "researchers" and "regulars." 

Regular nodes can adopt information or correct information. Regular nodes are represented by person shapes.  Regular nodes have an individual "change" property; the values for these are exponentially distributed with the mean set by the "openness-to-change" slider. 
Researchers have adopted? and corrected? properties but do not adopt and will always have correct information.  Researchers have a research-delay property which affects when they begin to exert influence in the network. Researchers are represented by cyan circle shapes in the network.

Nodes that have not adopted or corrected information are white.  Nodes that have adopted are represented by red or pink, depending on whether they adopt based on broadcast or social influence.  Nodes that have corrected are blue if corrected based on broadcast, sky if corrected based on social influence. 

Patches are also agents in this model, though only affecting the media-bias variants.

Two properties are defined for patches, "vote" and "total". Vote is used to decide patch color, with 0 being light green and 1 light orange, as well as how the patch affects broadcast influence.  Total is used in the irregular media bias variant during the setup phase and affects the vote property of the patch. In the irregular media bias variant, patches vote and change color, modifying the shape of the media environment.

There are also links in the network, which are established according to the network type. The links do not have specific properties or actions.
 
## ENVIRONMENT

The environment consists of one of three network types and one of three broadcast media environments. 

Network types can be:

* preferential attachment
* random 
* Watts-Strogatz small world

The media environment can be:

* **uniform**: all nodes have the same broadcast influence, which initially affects adoption only.  After research-delay has expired, broadcast influence affects adoption and correction proportional to the overall percentage of nodes which have adopted or corrected information.
* **irregular media bias**: in this variant, the media environment is setup during the setup procedure using a voting procedure similar to that in the "Voting Sensitivity Analysis" model in the model library.  Once patch color and vote have been finalized, they are used during the go procedure to modify broadcast influence. Nodes on green patches will have a bias toward correction (after research-delay) while nodes on orange patches will have a bias toward adoption. The color of surrounding patches also affects the extent of the bias.
* **media bias - block**: this variant is only different from the "irregular media bias" variant during setup and functions the same as it during the go procedure and adoption or correction.  During setup, patch color (and vote) are set according to patch y coordinate, depending on the initial-green-pct, with green patches toward the top of the world.
  

## ORDER

Setup:

1. Clears everything
2. Sets up default breed shapes
3. Sets up network
4. Sets up media environment, if relevant
5. Assigns breed to nodes
6. Initializes globals
7. Restarts ticks

Go:

1. Updates global values
2. Checks for stop conditions
3. If research-delay has passed, asks nodes which do not have corrected? if they want to correct information.
4. If re-adoption is not allowed, asks nodes with neither corrected? nor adopted? if they would like to adopt.
5. If re-adoption is allowed, asks nodes that have not adopted if they would like to adopt. 
6. Advances ticks

## THINGS TO NOTICE

If re-adoption is off, try running with the ticks slowed down so that you can see the initial adoption spread through the network. 

Correction is often slower than initial adoption, which corresponds to the difficulty in the real world of changing ideas once adopted. Some settings will result in correction occuring more quickly, both research-delay and openness-to-change make a difference here.

Some settings result in adoption persisting in parts of the network until stop-ticks (for stop-ticks in the 1000-5000 range).  

The media bias settings can result in local groups that persist with a view that is different from consensus.  

## THINGS TO TRY

Oscillation in the adoption rate can occur when re-adoption is permitted.  Keeping other  parameters the same try both settings for re-adoption.  

With the media bias variants, it's easier to see what regions are green or orange with the preferential attachment network. 


## EXTENDING THE MODEL 

The patches/media environment could change as the network adoption rate changes. 

A network model known to represent a real world social media environment could replace the networks generated here.

Research-delay could vary among researchers. Currecntly the individual delay property isn't fully used, but it could be used to allow researchers to affect correction and adoption of information on an individual schedule.


## NETLOGO FEATURES

This model uses the Network extension (nw) to generate networks.

## RELATED MODELS

Preferential attachment, Spread of disease, Virus on a network, Unit 4, Model 7 (Intro to Agent-Based Modeling, summer 2017, Santa Fe Institute, instructor was William Rand), Voting Sensitivity Analysis

## CREDITS AND REFERENCES

Preferential Attachment model used for parameters in layout of preferential attachment network. Virus on a Network and Unit 4 models used as starting point.

* Wilensky, U. (2005).  NetLogo Preferential Attachment model.  http://ccl.northwestern.edu/netlogo/models/PreferentialAttachment.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

* Stonedahl, F. and Wilensky, U. (2008).  NetLogo Virus on a Network model.  http://ccl.northwestern.edu/netlogo/models/VirusonaNetwork.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

* Rand, W. Introduction to Agent-Based Modeling (Summer 2017) Unit 4, Model. https://s3.amazonaws.com/complexityexplorer/ABMwithNetLogo/model-7.nlogo 7:Influentials. 

* Belief persverance: https://en.wikipedia.org/wiki/Belief_perseverance 

* Rand, W., Wilensky, U. (2008).  NetLogo Voting Sensitivity Analysis model.  http://ccl.northwestern.edu/netlogo/models/VotingSensitivityAnalysis.  Center for Connected Learning and Computer-Based Modeling, Northwestern Institute on Complex Systems, Northwestern University, Evanston, IL.

This model was submitted as a student project for the Intro to Agent-Based Modeling class, summer 2017, offered by Santa Fe Institute and taught by William Rand. 
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
NetLogo 6.0.2
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
1
@#$#@#$#@
