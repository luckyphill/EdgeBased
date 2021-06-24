classdef NicheBottom < AbstractSimulationData
	% Calculates the bottom of the niche

	properties 

		name = 'nicheBottom'
		data = 1;
		stroma

	end

	methods

		function obj = NicheBottom(stroma)
			% Need to provide the stromal cell 
			obj.stroma = stroma;
		end

		function CalculateData(obj, t)

			% The presumes the stromal cell is made up of a single edge along the
			% bottom, and a single edge on either left or right outer boundary
			% This means there are two node in the bottom corners, and the next node
			% encountered in order of increaasing height will be the lowest point of
			% the crypt, hence we find this and use it as the base of the crypt.

			heights = [obj.stroma.nodeList.y];
			base = sort(heights);
			obj.data = base(3);

		end
		
	end


end