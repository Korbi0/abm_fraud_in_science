import random
import statistics

class researcher:
    def __init__(self, open_to_fraud:bool,
    fraud_propensity:float,
    number_of_frauds_committed:int,
    number_of_frauds_detected:int,
    speciality,
    testimonial_norm,
    fraud_norm,
    reported_results,
    data_from_other_researchers) -> None:
        self.open_to_fraud = open_to_fraud
        self.fraud_propensity = fraud_propensity
        self.number_of_frauds_committed = number_of_frauds_committed
        self.number_of_frauds_detected = number_of_frauds_detected
        self.speciality = speciality
        self.testimonial_norm = testimonial_norm,
        self.fraud_norm = fraud_norm,
        self.reported_results = reported_results
        self.data_from_other_researchers = data_from_other_researchers
        self.trustwortyness_scores = dict()
        self.credences=dict()

    def report_research(self):
        experimental_result = self.speciality.get_experimental_result()
        commit_fraud = self.open_to_fraud & random.random() < self.fraud_propensity
        if not commit_fraud:
            self.report_research.append(experimental_result)
        else:
            self.report_research.append(1)
    
    def fraud_detection(self, risk_of_getting_caught):
        if self.number_of_frauds_committed == 0:
            return # If a researcher has not committed any frauds, none can be detected
        else:
            prob_of_getting_caught = 1 - ((1 - risk_of_getting_caught) ** (self.number_of_frauds_committed - self.number_of_frauds_detected))
            if random.random() < prob_of_getting_caught:
                self.number_of_frauds_detected += 1

    def update_credences(self):
        if self.testimonial_norm == "Reidian":
            self.reidian_updating()
        elif self.testimonial_norm == "Majoritarian Reidian":
            self.majoritarian_reidian_updating()
        elif self.testimonial_norm == "E-Truster":
            self.e_trusting()
        elif self.testimonial_norm == "Majoritarian E-Truster":
            self.majoritarian_e_trusting
        elif self.testimonial_norm == "Proximist":
            self.proximist()
        elif self.testimonial_norm == "Majoritarian Proximist":
            self.majoritarian_proximist()

    def form_opinions(self):
        for r_a in self.credences:
            o = self.form_opinion_about_research_area(r_a)
            self.credences[r_a] = o
                
    def form_opinion_about_research_area(self, r_a:research_area, all_researchers:list):
        # self.credences[self] = 1 
        weights_and_data = []
        if r_a != self.speciality:
            # If it is not one's own speciality, only binary opinions are available
            for resrchr in all_researchers:
                weights_and_data.append((self.credences[resrchr], self.data_from_other_researchers[resrchr]))
        
        else:
            
    
    def form_opinion_from_weights_and_data_list(self, weights_and_data_list):
        """weights_and_data_list needs to be a list of tuples, where each tuple has two entries:
        a weight and a data point. The weight represents the trustworthyness off the data point"""

        total_weights = 0
        sum_data = 0
        for weight, data in weights_and_data_list:
            total_weights += weight
            sum_data = weight * data
        outcome = sum_data / total_weights
        return outcome

    def reidian_updating(self, res_areas_dict:dict):
        self.reidian_consult_other_researcher(res_areas_dict)
        

    
    def reidian_consult_other_researcher(self, res_areas_dict:dict):
        for r_a in self.credences:
            # Select a random researcher with the same speciality
            person_to_consult = random.choice(res_areas_dict[r_a])
            if r_a == self.speciality:
                # If the person to consult has the same speciality, take over their data
                self.data_from_other_researchers[person_to_consult] = person_to_consult.reported_results
            else:
                self.data_from_other_researchers[person_to_consult] = person_to_consult.create_binary_opinion(person_to_consult.reported_results)


    def create_binary_opinion(self, reported_results):
        """
        this function should take in a list of reported results on a given question, and return a binary opinion on whether the question being investigated is to be answered affirmatively or negatively
        there are different ways that this can be realized. In the first iteration, I implement a simple averaging of the results and then a cutoff point at .5: if the average result is higher than .5,
        the researcher will conclude that the question is to be answered affirmatively
        an alternative would be to implement significance tests.
        """
        return round(statistics.mean(reported_results))




class research_area:
    def __init__(self, value) -> None:
        self.value = value
    
    def get_experimental_result(self, noise=.2):
        result = self.value + random.gauss(0, noise)
        return result


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
        self.res_areas = [research_area(random.random()) for i in range(self.number_of_res_areas)]
        return self.res_areas

    def get_researchers(self):
        researchers = []
        self.res_areas_dict = ()
        for res_area in self.res_areas:
            researchers_in_area = []
            for i in range(self.number_researchers_per_area):
                fraudulent = (random.random() < self.proportion_of_fraudulent_researchers)
                fraud_propensity = random.uniform(0, self.maximal_fraud_propensity)
                resrchr = researcher(open_to_fraud=fraudulent,
                    fraud_propensity=fraud_propensity,
                    number_of_frauds_committed=0,
                    number_of_frauds_detected=0,
                    speciality=res_area,
                    reported_results=[],
                    data_from_other_researchers=dict())
                resrchr.credences = {r_a: 0.5 for r_a in self.res_areas} # set initial credence to .5 on every question
                researchers.append(resrchr)
                researchers_in_area.append(resrchr)
            self.res_areas_dict[res_area] = researchers_in_area
            

        self.researchers = researchers
        return self.researchers

    def setup(self):
        self.get_research_areas()
        self.get_researchers()

    def run(self):
        for i in range(self.iterations):
            for researcher in self.researchers:
                researcher.report_research()
                researcher.fraud_detection()
                researcher.update_credences()


