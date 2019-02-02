# Magnet arrangment optimisation through genetic algorithm for Magnetic Drug Targeting in Cancer Therapy

## Optimization Model for drug targeting systems

In this Project, magnet parameters of a magnet array will be optimized in order to maximize the average mean magnetic flux density in a tumor model. 
COMSOL Multiphysics and Matlab Livelink are dependencies for this project.
COMSOL is used to simulate the physics and extract the magentic field for a given set of parameters. Parameters will be adjusted through a matlab implementation of a genetic algorithm in order to find the optimum magnetic arrangement for a given Tumor.
The user can set the number of magnets and by using a genetic algorithm, the magnet configurations with the highest magnetic flux densities will be extracted. 
We use by default two variables, the height and the width of a magnet. This can also work for much more variables. 
The user must give the numbers of magnet, that should be optimized.

 ![overview](https://github.com/sertopexamgio/genetic_algorithm_magnetic_drug_targeting/blob/master/overview.png)
    
### optimization()
This is the main function of the project.
To start the optimization you should call this function by giving the number of magnets, for e.g. optimization(3).
If you want to optimize a model with 3 magnets and a model with 5 magnets you can write for e.g. optimization( [3 5] ).
You can explicitly adjust more parameters (see Documentation in the source code), otherwise they will be set automatically to defaults.

### initializeLivelink()
This function initializes the connection between Comsol and Matlab Livelink.
It also returns the path where all the optimization Matlab files can be found. 
When the optimization has stopped or succeeded, the user has to stop the connection manually by closing the system terminal. 
If the user tries to start a new optimization with an existing Comsol-Matlab connection, an error message will be shown, thus there should be only one connection open. 
In this case the user has to terminate the previous connection before starting a new one.
If the function throws an error, it probably means that the appropriate paths could not be found. In this case try to find the paths or open manually the Comsol Multiphysics Server.

### buildComsolModel()
This function prepares the comsol model on which the parameters of the magnets will be adjusted and the simulations will be run.
It creates and set the comsol components (geometry, materials, mesh, physics etc.)

### geneticAlgorithm()
 A genetic algorithm is a search heuristic that mimics the process of natural evolution. 
It is used to generate useful solutions to optimization and search problems. 
Genetic algorithms belong to the larger class of evolutionary algorithms, which generate solutions to optimization problems using techniques inspired by natural evolution, such as inheritance, mutation, selection, and crossover.
“Genetic algorithms are on the rise in electromagnetics as design tools and problem solvers because of their versatility and ability to optimize in complex multimodal search spaces”
http://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=558650

### runComsol()
This function set the given magnet parameters and runs a simulation in Comsol.
It returns the average mean magnetic flux density in the constructed tumor domain.

### saveComsolModel()
If the stopping criteria (e.g. B > 0.4 T) has been met, the model with the best solution will be stored automatically. 

### The main function here is called "optimization".

To start the program write this command:

`[ <output_variables> ] = optimization( <input_variables> )`
