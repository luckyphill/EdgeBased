Release 1.0.1 accompanys the paper "A rigid body framework for multi-cellular modelling" by Brown et al. which can be found in preprint at https://doi.org/10.1101/2021.02.10.430170 and published in Nature Computational Science at https://doi.org/10.1038/s43588-021-00154-4.

Release 1.0.2 accompanies the paper "Understanding the mechanisms causing buckling of epithelial monolayers" which can be found in preprint at https://doi.org/10.1101/2024.04.01.587527.

********************************************************
How to use the edge-based approach MATLAB software tool
********************************************************

This is to accompany the papers "A rigid body framework for multi-cellular modelling" and "Understanding the mechanisms causing buckling of epithelial monolayers" by Brown et al. 
If you use this code for any purpose, academic, commercial or otherwise, please cite or link to these papers. 

If you have downloaded this from GitHub, then you should find a directory called "EdgeBased/". This will be the main working directory. All of the components needed to run the simulations presented in Brown et al. can be found in the subdirectory "src/", and the files that were used to produce the analysis shown in the paper can be found in "analysis/". After successfully running simulations, the additional subdirectory "SimulationOutput/" will be found, and if the Visualiser has been used to output images, these will be found in "Images/". If an analysis has been run, then any images will also be found in "Images/", and if so chosen the formatted data can be found int "AnalysisOutput/".

********************************************************
Preparation
********************************************************

Before simulating any models, the enivironment variable "EDGEDIR" must be set. This is so the simulation data output can be written in the correct location for the visualiser. "EDGEDIR" should be the full path to the contents of "EdgeBased/", which on a Mac or Unix machine will be something like "/Users/[yourusername]/[otherdirectories]/EdgeBased/", or a PC "C:\Users\\[otherdirectories]\EdgeBased\". This can be done within MATLAB by navigating to "EdgeBased" in the MATLAB file browser, and using the command

	setenv('EDGEDIR',pwd)
	
This won't persist after MATLAB is closed, so it is better to set it by using export in the terminal, or better yet in the .bash_profile or .bashrc files. In Windows this can be set using System Properties.

Also, make sure that everything in "src/" is added to the MATLAB path.

********************************************************
Running a simulation
********************************************************

To simulate a model, you need to make an instance of the simulation object that you would like to run. The different models are found in "EdgeBased/src/models/". Each has its own unique input variables that need to be set when creating the object. Details about the models are given in the comments of the .m file.
For example, to run a tumour spheroid model, create an instance of the Spheroid object:
	
	s = Spheroid(t0, tg, s, sreg, seed);

This will set the variables and prepare the simulation to run. By default, the time step size is 0.005. To change this use:
	
	s.dt = [new dt size];

The model can be simulated through time in a number of ways:

	s.NextTimeStep; % Advances a single time step
	s.NTimeSteps(n); % Advances n time steps
	s.RunToTime(t); % Advances time steps until the total simulation time reaches t

These will step through time without showing any output to screen, but will save data to file so it can be viewed with the Visualiser later on.
To view the current spatial state use:
	
	s.Visualise;

This can only be used to view the current timestep, since no previous time steps are held in memory.
If you want to view the simulation as it runs, you need to use:

	s.Animate(tsteps, sm);

Here tsteps is the number of time steps to advance, and sm is the sampling multiple, i.e. the number of time steps to skip between each frame. Skipping more frames can help speed up the simulation.
	
If you are running an over-lapping rods model (i.e. VolfsonExperiment), the visualising is slightly different:

	ve.VisualiseRods(r);
	ve.AnimateRods(tsteps, sm, r);

These require the input variable r which is the radius of the end-cap/width of the rod as you wish them to be drawn. Usually r=0.4 is a good value to use for VolfsonExperiment, but it will depend on the size of the rods used

********************************************************
					WARNING!!!
********************************************************

By default the complete spatial state of the simulation is written to file at every twentieth time step. This can result in very large text files if the cell count gets large - a spheroid simulation run to time 200 can produce files 100s of MBs in size. File output can be stopped by commenting out the line

	obj.AddDataWriter(WriteSpatialState(20, pathName));

found towards the end of the .m file for the simulation object.



********************************************************
Viewing a completed simulation
********************************************************

When a simulation is complete, you can view it using a Visuliser object. The Visualiser can be started in two ways:

	v = Visualiser(s);
	% or
	v = Visualsier(pathToOutput);

The first way hands in the simulation object and automatically finds the files. The second way needs the intermediate path to the output files. This can be found in the "SimulationOutput/" directory. For the models given here, the path will be of the form:

	pathToOutput = '[modelName]/[inputVariableGeneratedDirectory]'

For example

	pathToOutput = 'VolfsonExperiment/n50l5r5s20tg10w30f0.9t00da0ds1dl1a0_seed2'

To view the simulation, simply use

	v.VisualiseCells();
	% or
	v.VisualiseRods(r);

This will show an animation of the full simulation at the data points that are stored. If you wish to start from a later time step use:

	v.VisualiseCells(tstep);
	% or
	v.VisualiseRods(r,tstep);

To save an image of a specific time step to file use:

	v.PlotTimeStep(tstep);
	% or
	v.PlotRodTimeStep(r, tstep);

The simulation can be exported to a video file using:

	v.ProduceMovie();
	% or
	v.ProduceRodMovie(r);

And if you wish to only export a certain segment of the animation, then use:
	
	v.ProduceMovie(tstepstart, tstepend);
	% or
	v.ProduceRodMovie(r, tstepstart, tstepend);


********************************************************
Provided models
********************************************************

The models found in the "models/" subdirectory are the three models used in Brown et al. They can be run by creating an instance of the object and specifying the input variables. The standard input variables are outlined below, with values used in the paper given in brackets. There are additional variables in the .m files that can be modified if so desired, but the default values should result in stable simulations in most instances.

Tumour Spheroid model
Run using:
	
	s = Spheroid(t0, tg, s, sreg, seed);
	% t0 (=10) is the non growing phase duration
	% tg (=10) is the growth phase duration
	% hence t0 + tg is the total cell cycle length
	% s (=10) is the cell-cell interaction force law parameter used for both adhesion and repulsion
	% sreg (=5) is the perimeter normalising force
	% seed is used to seed the random number generator

Volfson Experiment model
Run using:

	ve = VolfsonExperiment(n, l, r, s, tg, w, seed);
	% n (=20) is the number of cells to seed the experiment with
	% l (=6) is the length of the cell. This includes the radius around the end of the cell
	% r (=5) is the rod growing force
	% s (=40) is the force pushing cells apart to their preferred distance
	% tg (=10) is the time to grow from new cell to full size
	% w (=30) is the width of the channel - the centre line will be y=0, so ymax = +/- w/2


Epithelial ring of cells model
Run using:

	r = RingBuckling(n, t0, tg, seed);
	% n (=20) is the number of cells in the ring, we restrict it to be  >10
	% t0 (=10) is the non growing phase duration
	% tg (=10) is the growth phase duration
	% hence t0 + tg is the total cell cycle length

********************************************************
Running analyses
********************************************************
The folder "analysis/" contains objects that will process pre-generated simulation output data and produce plots associated with the analysis. To run an analysis, you must first run the required models to t=200. A "SingleAnalysis" will produce plots for a single simulation, while a "MultiAnalysis" will produce plots for data averaged over several instaces of the same simulation with different RNG seeds.

For example, to run an analysis of the E. coli model first run

	ve = VolfsonExperiment(40, 6, 5, 40, 10, 20, 0.9, 1);
	ve.RunToTime(200);

to generate the simulation data, then run

	vsa = VolfsonSingleAnalysis(40, 6, 5, 40, 10, 20, 0.9, 1);
	vsa.AssembleData;
	vsa.PlotData;

For a multi-analysis, multiple simulations need to have been run to completion first. The multi-analysis files provided are for specific parameter sets, namely

	s = Spheroid(10, 10, 10, 5, seed);
	ve = VolfsonExperiment(20, 6, 5, 40, 10, 30, 0.9, seed);

where "seed" is replaced with a different RNG seed for each instance. To run the multi-analysis, you need to provide a vector of the RNG seeds used for the completed simulations. In Brown et al. the seeds are 1:20, hence to run the analysis run
	
	vma = VolfsonMultiAnalysis(1:20);
	vma.LoadSimulationData;
	vma.PlotData;

The method "LoadSimulationData" is recommended for large data sets, as it stores the processed data for later retrieval. The method "AssembleData" only loads the data into memory and does not save it. If you have used "LoadSimulationData" previously for an analysis, then using it again will load the processed data from file. If you wish to ignore the stored processed data and explicitly regenerate it, run

	vma.LoadSimulationData('flag');

where 'flag' can be any valid MATLAB string or variable.
