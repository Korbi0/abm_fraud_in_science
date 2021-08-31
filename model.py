from researcher import researcher, research_area, simulation
import random

random.seed(1)




if __name__ == "__main__":
    sim = simulation(number_research_areas=5,
        number_researchers_per_area=6,
        proportion_fraudulent_researchers=.3,
        maximal_fraud_propensity=.4,
        risk_of_getting_caught=.1,
        iterations=10,
        testimonial_norm="Reidian",
        fraud_norm="Ostrich")
    sim.run()
    print("Done")