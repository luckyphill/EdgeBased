********************************************************
How to use the edge-based approach MATLAB software tool
********************************************************

This is to accompany the paper "A rigid body approach to modelling cell cell interactions in 2D" by Brown et al.

If you have downloaded this from GitHub, then you should find a directory called "EdgeBased/". This will be the main working directory. All of the components needed to run the simulations presented in Brown et al. can be found in the subdirectory "src/". After successfully running simulations, the additional subdirectory "SimulationOutput/" will be found, and if the Visualiser has been used to output images, these will be found in "Images/".

********************************************************
Preparation
********************************************************

Before simulating any models, the enivironment variable "EDGEDIR" must be set. This is so the simulation data output can be written in the correct location for the visualiser. "EDGEDIR" should be the full path to the directory "EdgeBased/", which on a Mac will be something like "/Users/[yourusername]/[otherdirectories]/EdgeBased/". This can be done within MATLAB using setenv(), but it won't persist after MATLAB is closed, so it is better to set it by using export in the terminal, or better yet in the .bash_profile or .bashrc files.

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
	% n (=50) is the number of cells to seed the experiment with
	% l (=5) is the length of the cell. This includes the radius around the end of the cell
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