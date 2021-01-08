classdef AbstractCellCycleModel < matlab.mixin.SetGet
	% An abstract class that gets the basics of a cell cycle model

	properties

		age

		colourSet = ColourSet();

		colour = 1;

		containingCell

	end


	methods (Abstract)

		% Returns true if the cell meets the conditions for dividing
		ready = IsReadyToDivide(obj);
		% If a cell grows, then need to know the point in this growth
		% This should vary from 0 (equal the new cell size) to 1 (fully grown)
		% but there is no reason it can't go above 1 if max cell size is variable
		fraction = GetGrowthPhaseFraction(obj);
		% When a cell divides, duplicate the ccm for the new cell
		newCCM = Duplicate(obj);

	end

	methods

		function age = GetAge(obj)
			
			age = obj.age;
		end

		function SetAge(obj, age)

			obj.age = age;
		end

		function AgeCellCycle(obj, dt)

			obj.age = obj.age + dt;
		end

		function colour = GetColour(obj)

			colour = obj.colourSet.GetRGB(obj.colour);

		end


	end


end