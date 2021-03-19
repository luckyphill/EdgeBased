classdef TargetPerimeterSquareControlled < AbstractCellData
	% After a division event, there is a step change in the forces, leeading
	% to imbalances that trigger buckling. This attempts to stop this by gradually
	% changing the target area over a period of time

	properties 

		name = 'targetPerimeter'
		data = []

		fadeTime

	end

	methods

		function obj = TargetPerimeterSquareControlled(fadeTime)

			obj.fadeTime = fadeTime;
			
		end

		function CalculateData(obj, c)
			
			targetArea = c.cellData('targetArea').GetData(c);
			targetPerimeter = 2 * (1 + targetArea);


			if c.age < obj.fadeTime

				oldTargetPerimeter = c.cellData('cellPerimeter').GetData(c);

				proportion = (obj.fadeTime - c.age)/obj.fadeTime;
				targetPerimeter = (oldTargetPerimeter - targetPerimeter) * proportion + targetPerimeter;
				

			end

			obj.data = targetPerimeter;

		end
		
	end

end