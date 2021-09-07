from numpy import number
from researcher import researcher, research_area
import random
import statistics
from matplotlib import pyplot as plt
import math

class simulation:
    def __init__(self, number_research_areas,
    number_researchers_per_area,
    proportion_fraudulent_researchers,
    maximal_fraud_propensity,
    risk_of_getting_caught,
    iterations,
    testimonial_norm,
    fraud_norm) -> None:
        self.number_research_areas = number_research_areas
        self.number_researchers_per_area = number_researchers_per_area
        self.proportion_fraudulent_researchers = proportion_fraudulent_researchers
        self.maximal_fraud_propensity = maximal_fraud_propensity
        self.risk_of_getting_caught = risk_of_getting_caught
        self.iterations = iterations
        self.testimonial_norm = testimonial_norm
        self.fraud_norm = fraud_norm
        self.setup()



    def get_research_areas(self):
        self.res_areas = [research_area(id=(i+1), value=random.random()) for i in range(self.number_research_areas)]
        return self.res_areas

    def get_researchers(self):
        researchers = []
        self.res_areas_dict = dict()
        for res_area in self.res_areas:
            researchers_in_area = []
            for i in range(self.number_researchers_per_area):
                fraudulent = (random.random() < self.proportion_fraudulent_researchers)
                fraud_propensity = random.uniform(0, self.maximal_fraud_propensity)
                resrchr = researcher(id=self.researcher_count,
                    open_to_fraud=fraudulent,
                    fraud_propensity=fraud_propensity,
                    number_of_frauds_committed=0,
                    number_of_frauds_detected=0,
                    speciality=res_area,
                    reported_results=[],
                    testimonial_norm=self.testimonial_norm,
                    fraud_norm=self.fraud_norm,
                    data_from_other_researchers=dict())
                self.researcher_count += 1
                resrchr.credences = {r_a: 0.5 for r_a in self.res_areas} # set initial credence to .5 on every question
                researchers.append(resrchr)
                researchers_in_area.append(resrchr)

            # The res_areas_dict is a dictionary that maps each research area
            # to the list of specialists in that area
            self.res_areas_dict[res_area] = researchers_in_area

        self.researchers = researchers
        for res in self.researchers:
            res.res_areas_dict = self.res_areas_dict
        return self.researchers

    def setup(self):
        self.researcher_count = 1
        self.iteration = 1
        self.get_research_areas()
        self.get_researchers()
        original_trustworthyness = {r:1 for r in self.researchers}
        original_credences = {r_a:.5 for r_a in self.res_areas}
        for resrchr in self.researchers:
            resrchr.set_trustworthyness(original_trustworthyness)
            resrchr.set_credences(original_credences)
        
    def collect_data(self):
        for researcher in self.researchers:
            researcher.report_research()
    
    def detect_fraud(self):
        for researcher in self.researchers:
            researcher.fraud_detection(self.risk_of_getting_caught)
    
    def credence_updates(self):
        for researcher in self.researchers:
            researcher.update_credences()

    
    def specialists_distances_from_truth(self, area) -> list:
        """"
        Returns a list where each entry represents the distance of one specialist from
        the truth about their subject
        """
        distances = []
        for resrchr in self.res_areas_dict[area]:
            dist = abs(resrchr.credences[area] - area.value)
            distances.append(dist)

        return distances

    def number_of_non_specialists_with_correct_binary_opinion(self, area) -> int:
        """"
        Returns the number of non-specialists, who have the correct binary opinion about the given subject
        i.e. if the question is to be answered affirmatively (<-> the value is greater than .5), this many 
        people think that it is to be answered affirmatively
        """
        
        non_expert_researchers = [resrchr for resrchr in self.researchers if resrchr.speciality != area]
        correct_belief = round(area.value)
        non_expert_opinions = [r.credences[area] for r in non_expert_researchers]
        number_of_correct_binary_believers = 0
        for opinion in non_expert_opinions:
            if opinion == correct_belief:
                number_of_correct_binary_believers += 1
        
        return number_of_correct_binary_believers


    def run_single_iteration(self):
        """"
        Runs a single iteration of data-collection, fraud-detection and credence-updating
        """
        self.collect_data()
        self.detect_fraud()
        self.credence_updates()
        self.iteration += 1

    def run_with_plotting(self):
        specialists_avg_distances_from_truth = {r_a: [] for r_a in self.res_areas}
        number_of_nonspecialist_correct_believers = {r_a: [] for r_a in self.res_areas}
        iteration_list = []
        while self.iteration <= self.iterations:
            self.run_single_iteration()
            for r_a in self.res_areas:
                specialists_avg_distances_from_truth[r_a].append(statistics.mean(self.specialists_distances_from_truth(r_a)))
                number_of_nonspecialist_correct_believers[r_a].append(self.number_of_non_specialists_with_correct_binary_opinion(r_a))
            iteration_list.append(self.iteration)
        
        fig, axs = plt.subplots(math.ceil(self.number_research_areas / 2), 2)
        fig.tight_layout()
        for i in range(len(self.res_areas)):
            r_a = self.res_areas[i]
            axs[int(i/2), i % 2].plot(iteration_list, specialists_avg_distances_from_truth[r_a])
            axs[int(i/2), i % 2].set_title(f"{r_a} (value {round(r_a.value, 3)})")

        fig, axs = plt.subplots(math.ceil(self.number_research_areas / 2), 2)
        fig.tight_layout()
        for i in range(len(self.res_areas)):
            fig.tight_layout()
            r_a = self.res_areas[i]
            axs[int(i/2), i % 2].plot(iteration_list, number_of_nonspecialist_correct_believers[r_a])
            axs[int(i/2), i % 2].set_title(f"{r_a} (value {round(r_a.value, 3)})")

    def run(self):
        """
        Runs the chosen number of iterations (i.e. one complete simulation)
        """
        while self.iteration <= self.iterations:
            self.run_single_iteration()

    