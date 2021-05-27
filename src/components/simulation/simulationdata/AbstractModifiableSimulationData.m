classdef AbstractModifiableSimulationData < AbstractSimulationData
	% The same as AbstractSimulationData, but it allows the data
	% to be modified, throwing in a validation check

	methods

		function SetData(obj, d)
			% If the data needs to be directly modified
			if obj.DataIsValid(d)
				obj.data = d;
			else
				error('AMSD:WrongData', 'Data in unexpected format');
			end
			
		end

		function CalculateData(obj, t)

			% Does nothing. Need to do this for now. Later revisision will separate out
			% the function of modifiable data storage better

		end


	end

	methods (Abstract)

		% This method must return data
		correct = DataIsValid(obj, d)
		
	end

end