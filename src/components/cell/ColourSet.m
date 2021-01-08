classdef ColourSet < matlab.mixin.SetGet
	% The colours for rendering cells

	properties

		colourMap

		numToName

		nameToNum
		
	end

	methods

		function obj = ColourSet()

			% Don't really know a better way to set the property 
			names = {'PAUSE','GROW','STOPPED','DYING','STROMA', 'PILL', 'PILLGROW', 'ECOLI','ECOLISTOPPED'};

			values ={[0.9375 0.7383 0.6562],
						[0.6562 0.8555 0.9375],
						[0.6680 0.5430 0.4883],
						[0.5977 0.5859 0.5820],
						[0.9453 0.9023 0.6406],
						[0.2812 0.6641 0.2969],
						[0.6641 0.2812 0.6484],
						[0.7578 0.8633 0.3359],
						[0.4180 0.5000 0.0977]};

			obj.colourMap = containers.Map(names,values);

			obj.numToName = containers.Map( {1,2,3,4,5,6,7,8,9}, names);

			obj.nameToNum = containers.Map( names, {1,2,3,4,5,6,7,8,9});

		end

		function colour = GetRGB(obj, c)

			% Returns the RGB vector

			if isa(c, 'double')
				c = obj.numToName(c);
			end

			colour = obj.colourMap(c);

		end

		function colour = GetNumber(obj, c)

			% Returns the number matching the name
			colour = obj.nameToNum(c);

		end

	end

end
