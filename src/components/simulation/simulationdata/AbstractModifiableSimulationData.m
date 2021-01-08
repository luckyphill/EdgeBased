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

		function correct = DataIsValid(obj, d)

			% Not always needed, default to true so it doesn't
			% need to be implemented in every case
			correct = true;

		end

	end

end