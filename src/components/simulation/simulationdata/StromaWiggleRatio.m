classdef StromaWiggleRatio < AbstractSimulationData
	% Calculates the wiggle ratio of the Bottom of the cells

	properties 

		name = 'stromaWiggleRatio'
		data = 1;

		w % The width of the stroma

	end

	methods

		function obj = StromaWiggleRatio(w)
			
			obj.w = w;
			
		end

		function CalculateData(obj, t)

			len = 0;
			s = CellFree.empty();

			sizeOfSideEdges = 3.8; 
			% Hard coded based on 
			% stromaTop = -0.1;
			% stromaBottom = -4;
			% in DynamicLayer

			for i = 1:t.GetNumCells()
				% Find the stromal cell
				if t.cellList(i).cellType == 5 %
					s = t.cellList(i);
					break;
				end
			end

			if isempty(s)
				error('Couldnt find stroma');
			end

			% The longest three edges shouldn't be included
			for i = 1:length(s.elementList)

				l = s.elementList(i).GetLength();

				if l < sizeOfSideEdges
					len = len + l;
				end

			end

			obj.data = len/obj.w;

		end
		
	end


end