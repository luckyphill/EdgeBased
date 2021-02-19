classdef BottomWiggleRatio < AbstractSimulationData
	% Calculates the wiggle ratio of the Bottom of the cells

	properties 

		name = 'bottomWiggleRatio'
		data = 1;

	end

	methods

		function obj = BottomWiggleRatio
			% No special initialisation
			
		end

		function CalculateData(obj, t)

			l = 0;
			for i = 1:t.GetNumCells()
				if t.cellList(i).cellType == 1
					l = l + t.cellList(i).elementBottom.GetLength();
				end
			end

			sd = t.simData('boundaryCells');
			bcs = sd.GetData(t);
			cl = bcs('left');
			cr = bcs('right');

			w = cr.nodeBottomRight.x - cl.nodeBottomLeft.x;

			obj.data = l/w;

		end
		
	end


end