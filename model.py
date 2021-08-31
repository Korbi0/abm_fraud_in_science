from researcher import researcher, research_area
import random

random.seed(1)


def run_simulation(number_research_areas:int,
    number_researchers_per_area:int,
    proportion_of_fraudulent_researchers:float,
    maximal_fraud_propensity:float,
    risk_of_getting_caught:float,
    iterations:int,
    testimonial_norm:str,
    fraud_norm:str):
    day = 1
    # Counter for the day we are currently in
    researchers = []
    research_areas = []
    for i in range(number_research_areas):
        value = random.random()
        research_area.append(research_area(value))
        for j in range(number_researchers_per_area):
            fraudulent = (random.random() < proportion_of_fraudulent_researchers)
            fraud_propensity = random.uniform(0, maximal_fraud_propensity)




def get_research_areas(number_of_res_areas:int) -> list:
    return [research_area(random.random()) for i in range(number_of_res_areas)]




