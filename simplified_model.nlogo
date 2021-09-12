extensions [table]



breed [research_areas research_area]
research_areas-own [value] ; each research area consists of a question which has a definitive true value between 0 and 1 as its answer

undirected-link-breed [professional_connections professional_connection]

breed [researchers researcher]
researchers-own [credence open_to_fraud fraud_propensity number_of_frauds_committed number_of_frauds_detected reported_results node-clustering-coefficient data_from_other_researchers]


globals[number_of_agents clustering-coefficient average-path-length infinity question majority_convergence close_to_truth complete_convergence] ; partly taken from the code for  Kevin Zollman's paper "Social Network Structure and the Achievement of Consensus" provided on his website http://www.kevinzollman.com/papers.html

to setup
  clear-all
  ask patches [set pcolor white]
  reset-ticks

  set number_of_agents (number_of_research_areas * researchers_per_area)
  create-researchers number_of_agents


  ; The following three global variables will be used to check whether convegence has been achieved
  ; each will be filled with the tick-numbers of iterations at which the corresponding metrics are achieved
  ; and be reset to the empty list when the corresponding metric is not achieved at a given moment
  set majority_convergence []
  set close_to_truth []
  set complete_convergence []



  ask researchers [
    ; A proportion of scientists will be open to fraud. Each scientist has a corresponding chance to be of the fraudulent kind
    set open_to_fraud (random-float 1) < share_of_fraudulent_scientists

    ; Each scientist has their individual propensity for fraud. It only comes into play however if he/she is in principle open to fraud
    set fraud_propensity random-float highest_possible_fraud_propensity

    ; At the time of their birth, a scientist has not yet committed any frauds, nor have any been discovered
    set number_of_frauds_committed 0
    set number_of_frauds_detected 0

    ; A scientist also starts out with an empty list of reported results
    set reported_results []

    ; The initial credence of each scientist in the research question is an agnostic 50%
    set credence .5
    setxy random-xcor random-ycor
  ]


  ask researchers [

    ; Each researcher keeps a dictionary of the information they have received from the other researchers.
    set data_from_other_researchers table:make

    ; In the beginning, the dictionary is filled with the fact that all the other researchers are agnostic.
    ; this will be overridden as research is conducted and communication takes place
    let d data_from_other_researchers
    ask other researchers [
      ifelse take_only_binary_info_from_colleagues [ ;the format depends on whether we only exchange binary opinions or lists of the collected data
        table:put d who [1 0.5] ; Initially, each researcher has trustworthyness 1 and credence .5 in the question
      ]
      [
        table:put d who [1 [0.5]] ; Initially, each researcher has trustworthyness 1 and credence .5 in the question
      ]

    ]
  ]




  ; create network
  if Network = "Cycle" [cycle]
  if Network = "Wheel" [wheel]
  if Network = "Complete" [complete]


  create-research_areas 1 [
    ; the value of the question is a random number between 0 and 1, unless the switch for manually determining the difficulty is on
    set value random-float 1
    ifelse manually_set_difficulty [set_difficulty] [set value random-float 1.0]

    ; the global pointer question is set to point at the research question
    set question self

    ; the research question turtle should be invisible
    set color white
  ]

  layout-circle research_areas 5


  ask professional_connections [
    set color 67
  ]



end

to go
  ask researchers [

    ; Each iteration consists of three phases, starting with conducting and reporting research...
    report_research


    ; ... followed by the fraud detection phase...
    fraud_detection


    ;... and concluding with each researcher communicating with the others and updating their credence
    update_credences

  ]


  ; After each iteration, convergence of the three metrics we use is checked
  check_convergence

  tick
end

to check_convergence


  ; All three work in the same way: If the metric is fulfilled, add the current tick to the corresponding list
  ; if the metric is not fulfilled, reset the corresponding list to the empty list
  ; if the list of a certain metric reaches the length of 500, then the first tick in the list
  ; will have been the tick at which lasting convergence was reached.


  ifelse avg_dist_from_truth_very_small and (ticks > 0) [
    set close_to_truth (lput ticks close_to_truth)
  ] [set close_to_truth []]

  ifelse eighty_percent_true_opinion and (ticks > 0)[
    set majority_convergence (lput ticks majority_convergence)
  ] [set majority_convergence []]

   ifelse hundred_percent_true_opinion and (ticks > 0)[
    set complete_convergence (lput ticks complete_convergence)
  ] [set complete_convergence []]

  if (length close_to_truth = 500)[print (word "It took " (item 0 close_to_truth) " iterations to come close to the truth")]
  if (length complete_convergence = 500)[print (word "It took " (item 0 complete_convergence) " iterations to  completely converge on the truth.")]
  if (length majority_convergence = 500) [print (word "It took " (item 0 majority_convergence) " iterations for 80% of researchers to adopt the correct binary opinion")]
end

to set_difficulty
  ; should be called by a resarch area
  ; the question's value will be set closer to .5 if difficulty is higher
  if (difficulty_of_research_question = "easy") [set value .15]
  if (difficulty_of_research_question = "difficult") [set value .4]
  if (difficulty_of_research_question = "very difficult") [set value .47]
  if (difficulty_of_research_question = "extremely difficult") [set value .49]

end



to report_research
  ; should be called by a researcher
  ; simulates the conducting of an experiment and recording the result to the researcher's own
  ; "reported_results" list attribute

  let experimental_result get_experimental_result question
  ifelse open_to_fraud
  [ ; the scenario where the researcher is open to committing fraud:
    let commits_fraud ((random-float 1) < fraud_propensity) ; roll the dice on whether the researcher committs fraud this round
    ifelse commits_fraud
    [
      set reported_results (lput 1 reported_results) ;if fraud is committed, the scientist reports a positive result independent of their experimental result
      set number_of_frauds_committed (number_of_frauds_committed + 1)
    ]
    [
      set reported_results (lput experimental_result reported_results) ; if no fraud is committed, the researchers enters their true experimental result into the record
    ]
  ]
  [ ; the scenario where the researcher is completely, 100% honest:
    set reported_results (lput experimental_result reported_results)
  ]
end


to-report get_experimental_result [res_area]
  ; this function simulates conducting an experiment in the research area 'res_area'

  ; first, we determine the true answer to the question inverstigated in 'res_area
  let v ([value] of res_area)

  ; the experimental result will not be the exactly true number, but instead there will be some Gaussian noise
  ; (to be set with the 'noise_in_experiments'slider in the interface
  let noise random-normal 0 noise_in_experiments

  ; The result the researcher gets is the combination of the truth with the noise
  let result (v + noise)
  report result
end



to-report form_binary_opinion [rep_results]
  ; this function should take in a list of reported results on a given question, and return a binary opinion on whether the question being investigated is to be answered affirmatively or negatively
  ; there are different ways that this can be realized. In the first iteration, I implement a simple averaging of the results and then a cutoff point at .5: if the average result is higher than .5,
  ; the researcher will conclude that the question is to be answered affirmatively
  ; an alternative would be to implement significance tests.

  if (length rep_results) = 0 [report .5] ; if the researcher does not have any data, they are agnostic, i.e. .5
  report round (mean rep_results)
end


to fraud_detection
  ; should be called by a researcher
  ; simulates the risk of getting caught for your frauds


  ifelse number_of_frauds_committed = 0 [
    ; if no frauds have been committed, do nothing
  ]
  [
    ; the probability of a fraud being detected is modeled by a geometric distribution
    let probability 1 - ((1 - risk_of_getting_caught)^(number_of_frauds_committed - number_of_frauds_detected))
    if (random-float 1) < probability [
      ; if a fraud is detected, increase the number of detected frauds by one
      set number_of_frauds_detected (number_of_frauds_detected + 1)

      ; If the fraud-related norm being used is the "Rigorous Eliminator", a fraud being detected leads to the fraudster being immediately excised from the community
      if "Fraud_Related_Norm" = "Rigorous Eliminator" [die]
    ]
  ]

end


to update_credences
  ; should be called by a researcher
  ; depending on which testimonial norm is in use, communicate and update credence in accordance with that rule

  if Testimonial_Norm = "Reidian" [reidian_updating]
  if Testimonial_Norm = "Majoritarian Reidian" [majoritarian_reidian_updating]
;  if Testimonial_Norm = "E-Truster" [e_trusting]
;  if Testimonial_Norm = "Majoritarian E-Truster" [majoritarian_e_trusting]
;  if Testimonial_Norm = "Proximist" [proximist]
;  if Testimonial_Norm = "Majoritarian Proximist" [majoritarian_proximist]


end




to reidian_updating
  ; should be called by a researcher
  ; update credence about the research question by collecting the opinion/data of a random neighbor


  ; set d to be a pointer to the researchers dictionary for data from other researchers
  let d data_from_other_researchers

  ifelse take_only_binary_info_from_colleagues [
    ask one-of in-professional_connection-neighbors [ ; select a random neighbor the researcher is connected to professionally

      ; get their binary opinion on the research question
      let binary_opinion form_binary_opinion reported_results

      ; get their trustworthiness
      let trustworthyness get_trustworthyness


      ; enter both the trustworthiness of the person you talked to and the data they gave you into your dictionary
      table:put d who (list trustworthyness binary_opinion)
    ]
  ]
  [
    ask one-of in-professional_connection-neighbors [

      ; get their data
      let data reported_results

      ; get their trustworthiness
      let trustworthyness get_trustworthyness

      ; enter both the trustworthiness of the person you talked to and the data they gave you into your dictionary
      table:put d who (list trustworthyness data)
    ]
  ]


  ; form a new opinion on the research question
  form_opinion_non_majoritarian_updating

end


to form_opinion_non_majoritarian_updating
  ; should be called by a researcher, usually after they have gathered data
  ; should only be called if we are not using a "Majoritarian" testimonial norm

  ; we will do a weighted sum of all the data the agent has access to
  ; where the weights will be the trustworthinesses of the people they got the data from
  let total_weights 0
  let sum_data 0
  let result "None"



  ifelse take_only_binary_info_from_colleagues [
    foreach table:to-list data_from_other_researchers  [ ; this is the data from other researchers
      x -> let data (item 1 x)

      ; item 0 of data is the trustworthiness score. This serves as the weight
      let w (item 0 data)
      set total_weights (total_weights + w)

      ; item 1 of data is the (binary) opinion of the agent
      set sum_data (sum_data + w * (item 1 data))
    ]

    ; we are done with summing the data we have from other researchers. now we add our own data.
    ; a researcher's trust in their own results never sinks too low
    let w max list get_trustworthyness ((count researchers) / (max list ticks 1))


    foreach reported_results [ ; this is the researcher's own data
      z -> set total_weights (total_weights + w)
      set sum_data (sum_data + w * z)
    ]

    ; the result is obtained by dividing the sum of the data by the sum of the weights
    set result (sum_data / total_weights)
  ]
  [

    ; this is the case where we do not get only binary data from other researchers
    foreach table:to-list data_from_other_researchers [ ; this is the data from other researchers


      x -> let data (item 1 x)

      ; item 0 of data is the trustworthiness score. This serves as the weight
      let weight (item 0 data)

      ; item 1 of data is the data we got from the agent in question. it is a list of results.
      foreach (item 1 data) [
        y -> set total_weights (total_weights + weight)
        set sum_data (sum_data + weight * y)
      ]
    ]

    ; we are done with summing the data we have from other researchers. now we add our own data.
    let w get_trustworthyness
    foreach reported_results [ ; this is the researcher's own data
      z -> set total_weights (total_weights + w)
      set sum_data (sum_data + w * z)
    ]

    ; the result is obtained by dividing the sum of the data by the sum of the weights
    set result (sum_data / total_weights)
  ]

  ; update the agent's credence attribute
  set credence result

end

to majoritarian_reidian_updating
  ; should be called by a researcher
  ; update credence about the research question by collecting the opinions of all neighbors and pooling them
  ; only makes sense if take_only_binary_info_from_colleagues is true



  ifelse not take_only_binary_info_from_colleagues [print "Majoritarian Reidian updatig only makes sense if you take binary info"]
  [

    let avg 0
    let total_weights 0

    ask in-professional_connection-neighbors [ ; get the opinions of the researchers in your network
      let w get_trustworthyness
      set total_weights (total_weights + w)
      set avg (avg + w * (form_binary_opinion reported_results))
    ]


    ; also take your own opinion into account
    let w max list get_trustworthyness ((count researchers) / (max list ticks 1)) ; a researcher's trust in their own results never sinks too low
    foreach reported_results [ ; this is the researcher's own data
      z -> set total_weights (total_weights + w)
      set avg (avg + w * z)
    ]
    let result (avg / total_weights)
    set credence result

  ]
end

;to e_trusting
;
;end
;
;
;to majoritarian_e_trusting
;
;end
;
;
;
;to proximist
;
;end
;
;
;
;to majoritarian_proximist
;
;end


to-report get_trustworthyness
  ; should be called by a researcher
  ; reports their trustworhtiness-score
  ; depending on which fraud-related norm is in play


  ; If the ostrich norm is used, every researcher always keeps full credibility
  if Fraud_Related_Norm = "Ostrich"[report 1]


  ; If the Discounter norm is used, a researcher who has not yet been discovered to have cheated has trustworthiness 1
  ; and a researcher who has been found to commit fraud some times receives a trustworthiness score
  ; that depends on the parameter "fraud_discount_factor"and the frequency they have been found to cheat

  if Fraud_Related_Norm = "Discounter" [
    if number_of_frauds_detected  = 0 [report 1]

    let fraud_factor (fraud_discount_factor * (number_of_frauds_detected / (max list 1 ticks)))
    let trustworthyness 1 - fraud_factor

    ; trustworthiness can never fall below 0
    report max (list trustworthyness 0)
  ]


  ; If the Eliminator norm is used, any researcher who has committed at least one fraud
  ; is completely distrusted and has trustworthiness 0
  ; any researcher that has never been discovered to have cheated keeps full trustworthiness of 1
  if Fraud_Related_Norm = "Rigorous Eliminator" [
    ifelse (number_of_frauds_detected  = 0) [report 1] [report 0]
  ]
  if Fraud_Related_Norm = "Omniscient Discounter"[
    ifelse open_to_fraud [report 1 - fraud_discount_factor] [report 1]
  ]
end







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; for plotting
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report number_of_reserachers_with_correct_binary_opinion
  ; If the research question hasn't been initialized yet, no researcher has the correct opinion
  if (question = 0) [report 0]

  let correct round([value] of question)
  let i 0

  ; If no researcher has been initialized, no researcher has the correct opinion
  ifelse ((count researchers) = 0) [report 0] [

  ask researchers with [credence != .5] [
    if round(credence) = correct [set i (i + 1)]
  ]
    report i]
end


to-report average_credence
  ; what is the average opinion of all researchers


  let l []
  ask researchers [
    set l (lput credence l)
  ]
  let average .5
  ifelse ((length l) = 0) [set average .5] [set average mean l]

  report average
end


to-report average_distance_from_truth
  ; what is the distance between the truth and the average opinion of all researchers

  report abs (average_credence - true_value)
end


to-report true_value
  ; what is the true value of the research question


  ; If the research question hasn't been initialized yet, technically there is no true value; but
  ; we set it to .5 to represent agnosticism.
  if (question = 0) [report 0.5]
  let truth 0
  ask question [set truth value]
  report truth
end


to-report trust_in_fraudsters
  ; what is the sum over all fraudsters of the trustworthiness they are thought to have

  let i 0
  ask researchers with [open_to_fraud] [
    set i (i + get_trustworthyness)
  ]
  report i
end


to-report eighty_percent_true_opinion
  ; do at least 80% of researchers hold the correct binary opinion


  let i count researchers
  let k number_of_reserachers_with_correct_binary_opinion

  let r ((k / i) > .8)
  report r
end


to-report hundred_percent_true_opinion
  ; do all researchers hold the correct opinion

  let r (number_of_reserachers_with_correct_binary_opinion = (count researchers))
  report r
end


to-report avg_dist_from_truth_very_small
  ; is the distance between the average opinion of all researchers and the truth smaller than the given tolerance

  report average_distance_from_truth < tolerance
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; code for creating network structures
; taken from the code for  Kevin Zollman's paper "Social Network Structure and the Achievement of Consensus"
; provided on his website http://www.kevinzollman.com/papers.html
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to link-n
  ask researchers [create-links-with n-of degree other researchers ]
  repeat 500 [ layout-spring researchers links 0.5 2 1 ]
end

to cycle
  ifelse ((degree mod 2) != 0 ) or (degree > count researchers)
  [
    user-message "Degree error"
  ]
  [
    let i 1
    while [2 * i <= degree ]
    [
      let n 0
      while [n < count turtles] [
        ask turtle n [create-professional_connection-with researcher ( (n + i) mod count researchers) ]
        set n n + 1
      ]
      set i i + 1
    ]
  ]
  layout-circle sort researchers 15
end

to wheel
  ask researcher 0 [create-professional_connections-with other researchers setxy 0 0]

  let n 1
  while [n < count researchers] [
    ask researcher n [create-professional_connection-with researcher ( (n mod (count researchers - 1)) + 1)  ]
    set n n + 1
  ]
  let outside (turtle-set researchers with [who > 0])
  layout-circle sort outside 15
end

to complete
  ask researchers [create-professional_connections-with other researchers]
  layout-circle researchers 15
end


; Clustering computations

to-report in-neighborhood? [ hood ]
  report ( member? end1 hood and member? end2 hood )
end


to find-clustering-coefficient
  ifelse all? turtles [count link-neighbors <= 1]
  [
    ;; it is undefined
    ;; what should this be?
    set clustering-coefficient 0
  ]
  [
    let total 0
    ask turtles with [ count link-neighbors <= 1]
      [ set node-clustering-coefficient "undefined" ]
    ask turtles with [ count link-neighbors > 1]
    [
      let hood link-neighbors
      set node-clustering-coefficient (2 * count links with [ in-neighborhood? hood ] /
                                         ((count hood) * (count hood - 1)) )
      ;; find the sum for the value at turtles
      set total total + node-clustering-coefficient
    ]
    ;; take the average
    set clustering-coefficient total / count turtles with [count link-neighbors > 1]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
885
37
1322
475
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
1
1
1
ticks
30.0

SLIDER
69
561
347
594
number_of_research_areas
number_of_research_areas
1
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
69
333
345
366
researchers_per_area
researchers_per_area
0
100
25.0
1
1
NIL
HORIZONTAL

SLIDER
70
528
347
561
degree
degree
0
100
2.0
1
1
NIL
HORIZONTAL

BUTTON
71
37
137
70
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
137
37
200
70
NIL
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

SLIDER
70
366
345
399
noise_in_experiments
noise_in_experiments
0
1
0.5
0.05
1
NIL
HORIZONTAL

SLIDER
70
429
346
462
highest_possible_fraud_propensity
highest_possible_fraud_propensity
0
1
0.5
.05
1
NIL
HORIZONTAL

SLIDER
70
398
345
431
share_of_fraudulent_scientists
share_of_fraudulent_scientists
0
1
0.4
.05
1
NIL
HORIZONTAL

SLIDER
70
462
345
495
risk_of_getting_caught
risk_of_getting_caught
0
1
0.05
.05
1
NIL
HORIZONTAL

SLIDER
70
495
346
528
fraud_discount_factor
fraud_discount_factor
0
10
2.0
.5
1
NIL
HORIZONTAL

SWITCH
69
301
344
334
take_only_binary_info_from_colleagues
take_only_binary_info_from_colleagues
0
1
-1000

PLOT
543
88
886
238
Number of researchers with correct binary opinion
ticks
researchers
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot number_of_reserachers_with_correct_binary_opinion"

PLOT
542
238
885
388
average credence vs truth
ticks
avg credence
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot average_credence"
"pen-1" 1.0 0 -13840069 true "" "plot true_value"

SWITCH
66
251
238
284
manually_set_difficulty
manually_set_difficulty
0
1
-1000

PLOT
544
386
886
536
average distance from truth
ticks
distance
0.0
10.0
0.0
0.4
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot average_distance_from_truth"

MONITOR
544
537
713
582
Avg distance from truth
average_distance_from_truth
17
1
11

MONITOR
714
536
887
581
C. trust in fraudsters
trust_in_fraudsters
17
1
11

MONITOR
714
580
887
625
80% correct opinions
eighty_percent_true_opinion
17
1
11

INPUTBOX
428
581
544
641
tolerance
0.1
1
0
Number

MONITOR
544
580
713
625
Avg opinion close to truth
avg_dist_from_truth_very_small
17
1
11

PLOT
886
475
1086
625
Cumulative trust in fraudsters
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot trust_in_fraudsters"

CHOOSER
69
84
240
129
Testimonial_Norm
Testimonial_Norm
"Reidian" "Majoritarian Reidian"
0

CHOOSER
69
128
259
173
Fraud_Related_Norm
Fraud_Related_Norm
"Ostrich" "Discounter" "Rigorous Eliminator" "Omniscient Discounter"
2

CHOOSER
69
172
207
217
Network
Network
"Complete" "Cycle" "Wheel"
1

CHOOSER
238
251
458
296
difficulty_of_research_question
difficulty_of_research_question
"easy" "difficult" "very difficult" "extremely difficult"
0

TEXTBOX
241
238
485
266
only relevant if \"manually set difficulty\" is on
11
0.0
1

TEXTBOX
73
592
348
648
should always be 1. Future work might extend the model to allow for multiple research areas.
11
0.0
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
NetLogo 6.2.0
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
