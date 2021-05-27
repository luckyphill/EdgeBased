classdef TargetPerimeterControlled < AbstractCellData
	% After a division event, there is a step change in the forces, leeading
	% to imbalances that trigger buckling. This attempts to stop this by gradually
	% changing the target area over a period of time

	properties 

		name = 'targetPerimeter'
		data = []

		new
		grown
		fadeTime

	end

	methods

		function obj = TargetPerimeterControlled(new, grown, fadeTime)

			obj.fadeTime = fadeTime;
			obj.new = new;
			obj.grown = grown;
			
		end

		function CalculateData(obj, c)
			
			fraction = c.CellCycleModel.GetGrowthPhaseFraction();

			targetPerimeter = obj.new + fraction * (obj.grown - obj.new);

			if c.age < obj.fadeTime

				oldTargetPerimeter = c.cellData('cellPerimeter').GetData(c);

				proportion = (obj.fadeTime - c.age)/obj.fadeTime;
				targetPerimeter = (oldTargetPerimeter - targetPerimeter) * proportion + targetPerimeter;
				

			end

			obj.data = targetPerimeter;

		end
		
	end

end