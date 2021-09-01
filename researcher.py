import random
import statistics
import copy



class researcher:
    def __init__(self, id:int,
    open_to_fraud:bool,
    fraud_propensity:float,
    number_of_frauds_committed:int,
    number_of_frauds_detected:int,
    speciality,
    testimonial_norm,
    fraud_norm,
    reported_results,
    data_from_other_researchers) -> None:
        self.id = id
        self.open_to_fraud = open_to_fraud
        self.fraud_propensity = fraud_propensity
        self.number_of_frauds_committed = number_of_frauds_committed
        self.number_of_frauds_detected = number_of_frauds_detected
        self.speciality = speciality
        self.testimonial_norm = testimonial_norm
        self.fraud_norm = fraud_norm
        self.reported_results = reported_results
        self.data_from_other_researchers = data_from_other_researchers
        self.trustwortyness_scores = dict()
        self.credences=dict()

    def __str__(self) -> str:
        return f"Researcher {self.id}"

    def report_research(self):
        experimental_result = self.speciality.get_experimental_result()
        commit_fraud = self.open_to_fraud and random.random() < self.fraud_propensity
        if not commit_fraud:
            self.reported_results.append(experimental_result)
        else:
            self.reported_results.append(1)
    
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
                
    def form_opinion_about_research_area(self, r_a):
        all_researchers = list(self.trustwortyness_scores.keys())
        # self.trustworthyness[self] = 1 
        weights_and_data = []



        if r_a != self.speciality:
            # If it is not one's own speciality, only binary opinions are available
            for resrchr in all_researchers:
                if resrchr.speciality != r_a:
                    continue
                try:
                    data_from_researcher = self.data_from_other_researchers[resrchr]
                except KeyError:
                    # print(f"Researcher {self} hasn't gotten data from researcher {resrchr} yet.")
                    continue
                weights_and_data.append((self.trustwortyness_scores[resrchr], data_from_researcher))
        
        else:
            for resrchr in all_researchers:
                if resrchr.speciality != r_a:
                    continue
                try:
                    data_from_researcher = self.data_from_other_researchers[resrchr]
                except KeyError:
                    # print(f"Researcher {self} hasn't gotten data from researcher {resrchr} yet.")
                    continue
                for datapoint in data_from_researcher:
                    weights_and_data.append((self.trustwortyness_scores[resrchr], datapoint))
            for datapoint in self.reported_results:
                weights_and_data.append((self.trustwortyness_scores[self], datapoint))
        
        opinion = self.form_opinion_from_weights_and_data_list(weights_and_data)

        self.credences[r_a] = opinion
        return opinion

    
    def form_opinion_from_weights_and_data_list(self, weights_and_data_list):
        """weights_and_data_list needs to be a list of tuples, where each tuple has two entries:
        a weight and a data point. The weight represents the trustworthyness off the data point"""

        total_weights = 0
        sum_data = 0
        for weight, data in weights_and_data_list:
            total_weights += weight
            sum_data += weight * data
        outcome = sum_data / total_weights
        return outcome

    def reidian_updating(self):

        self.reidian_consult_other_researcher()
        self.form_opinions()
        

    
    def reidian_consult_other_researcher(self):
        res_areas_dict = self.res_areas_dict
        for r_a in self.credences:
            # Select a random researcher with the same speciality
            person_to_consult = random.choice(res_areas_dict[r_a])
            while person_to_consult == self:
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
        try:
            return round(statistics.mean(reported_results))
        except statistics.StatisticsError:
            return .5
    
    def set_trustworthyness(self, trustworthyness_dict):
        self.trustwortyness_scores = copy.copy(trustworthyness_dict)

    def set_credences(self, credences_dict):
        self.credences = copy.copy(credences_dict)
    




class research_area:
    def __init__(self, id, value) -> None:
        self.id = id
        self.value = value
    
    def __str__(self):
        return f"Research Area {self.id}"
    
    def get_experimental_result(self, noise=.2):
        result = self.value + random.gauss(0, noise)
        return result




