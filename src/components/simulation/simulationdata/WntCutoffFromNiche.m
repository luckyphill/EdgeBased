classdef WntCutoffFromNiche < AbstractSimulationData
	% Calculates the position where the wnt gradient drops below
	% the threshold for allowing cell division. This is intended to be used
	% in a cell cycle model to determine whena cell exits the proliferative
	% state. It calculates this position based on the bottom of the crypt
	% which will be dynamically changing under the stresses of proliferation

	properties 

		name = 'wntCutoff'
		data = 1;
		stroma
		cutoff

	end

	methods

		function obj = WntCutoffFromNiche(stroma, cutoff)
			% Need to provide the stromal cell 
			obj.stroma = stroma;
			obj.cutoff = cutoff;
		end

		function CalculateData(obj, t)

			% The presumes the stromal cell is made up of a single edge along the
			% bottom, and a single edge on either left or right outer boundary
			% This means there are two node in the bottom corners, and the next node
			% encountered in order of increaasing height will be the lowest point of
			% the crypt, hence we find this and use it as the base of the crypt.
			% The cutoff will be a fixed distance from this point, hence the cutoff
			% height will be rigidly attached to the base, without any smoothing

			heights = [obj.stroma.nodeList.y];
			base = sort(heights);
			base = base(3);


			obj.data = base + obj.cutoff;

		end
		
	end


end