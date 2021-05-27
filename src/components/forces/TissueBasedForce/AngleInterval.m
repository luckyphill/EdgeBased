classdef AngleInterval < handle

	% A class to handle the successive addition of angle intervals
	% The goal is to keep track of the total portion of a circle that
	% has been visited. The portion visited is passed in as an interval
	% and the interval is added to the sum total of the intervals visited

	% When an interval is added it reports back the portion that was visted
	% for the first time. It also check to see if the whole circle has been
	% visited. Since this is a circle, the intervals are periodic, so
	% we take the principle argument assuming -pi < theta <= pi
	% The interval can be given in any angles as long as the zero point
	% is the positive x axis

	% interval must be passed in anti-clockwise order, so the second angle
	% in the interval pair is anti-clockwise of the first angle

	% AT THIS POINT IT EXPECTS THE PRINCIPLE ARGUMENT

	properties

		ints

		PI = 3.1415926535;
	
	end


	methods

		function obj = AngleInterval()

			% The intervals are stored as a list of the end points
			% This works since there are no overlaps in the stored intervals
			% The only additional thing we need to be aware of is the which
			% of even or odd indices are the start or end of intervals

			% I think odd will always be the start
			obj.ints =  [];

		end

		function [uVAngle, varargout] = GetUnvistedAngle(obj, interval)

			% Check through the interval to see where its been already
			% and return the portion that hasn't been visited

			% By default just returns the cumulative angle remaining
			% if you want, you can get the actual interval segment
			% in varargout as a list of start and finish values


			remInt = [];

			if interval(2) < 0 && interval(1) > 0
				% We are lapping over the branch cut, so split into two ints
				% this only holds true assuming anti-clockwise from 1 to 2

				int1 = [interval(1), obj.PI];
				int2 = [-obj.PI, interval(2)];

				[uVAngle1, remInt1] = GetUnvistedAngle(obj, int1);
				[uVAngle2, remInt2] = GetUnvistedAngle(obj, int2);

				uVAngle = uVAngle1 + uVAngle2;

				remInt = [remInt1, remInt2];

			else

				% Compare the interval to the current set of visited interval

				if isempty(obj.ints)
					% The first interval is a gimme
					obj.ints = interval;

					remInt = interval;
					uVAngle = interval(2) - interval(1);

				else

					% Otherwise, need to search

					[uVAngle, remInt] = obj.GetAngleAndRepairIntervals(interval);

				end

			end

			varargout = {remInt};

		end

		function [startI, finishI] = GetStartAndFinishIndices(obj, interval)

			% Find the indices that the interval end points are smaller than
			% If it gets to the end and either is a nan, then it is bigger than
			% all the intervals existing

			startI = nan;
			finishI = nan;

			for i = 1:length(obj.ints)

				if ~isnan(startI) && ~isnan(finishI)
					break;
				end

				% Since intervals are ordered, just need to find the first point where it exceeds
				if isnan(startI)  && interval(1) < obj.ints(i)
					% start is in this interval
					startI = i;
				end

				if isnan(finishI) && interval(2) < obj.ints(i)
					% finish is in this interval
					finishI = i;

				end

			end

			if finishI < startI
				error('AI:WrongI','finishI is less than startI for [%g, %g]', interval(1), interval(2))
			end

		end

		function [uVAngle, remInt] = GetAngleAndRepairIntervals(obj, interval)


			[startI, finishI] = obj.GetStartAndFinishIndices(interval);

			% Handle special cases first
			
			% Same interval, after all exisiting intervals
			if isnan(finishI) && isnan(startI)
				% Interval extends past exisiting intervals
				obj.ints = [obj.ints, interval];
				remInt = interval;
				uVAngle = interval(2) - interval(1);

			end

			% Same interval, before all existing intervals
			if startI == 1 && finishI == 1

				% Interval is before existing intervals
				obj.ints = [interval, obj.ints];
				remInt = interval;
				uVAngle = interval(2) - interval(1);

			end

			% Same interval, but not at the end or the start
			if startI == finishI && startI ~= 1
				
				if rem(startI,2) == 0
					% Interval is entirely inside existing interval
					
					remInt = [];
					uVAngle = 0;

				elseif rem(startI,2) == 1

					% Intervals is entirely outside an existing interval
					obj.ints = [obj.ints(1:startI-1), interval, obj.ints(startI:end)];
					remInt = interval;
					uVAngle = interval(2) - interval(1);

				else
					% Something weird has happened
					error('AI:CantHappen','Same interval, not odd or even: startI %g, finishI %g', startI, finishI);
				end
			
			end

			
			% Ends after all, starts in the middle and not at the beginning
			if isnan(finishI) && ~isnan(startI)% && startI ~= 1

				% Repair the end

				if rem(startI,2)==1

					% Start is outside an interval
					uVAngle = obj.ints(startI) - interval(1);
					remInt = [interval(1), obj.ints(startI)];

					for i = startI+1:2:length(obj.ints)-2
						
						uVAngle = uVAngle +  (obj.ints(i+1) - obj.ints(i));
						remInt = [remInt, obj.ints(i), obj.ints(i+1)];
					end
					
					uVAngle = uVAngle +  (interval(2) - obj.ints(end));
					remInt = [remInt, obj.ints(end), interval(2)];

					obj.ints = [obj.ints(1:startI-1), interval];

				elseif rem(startI,2)==0
					% Start is inside an interval

					uVAngle = 0;
					remInt = [];

					for i = startI:2:length(obj.ints)-2
						
						uVAngle = uVAngle +  (obj.ints(i+1) - obj.ints(i));
						remInt = [remInt, obj.ints(i), obj.ints(i+1)];
					end

					uVAngle = uVAngle +  (interval(2) - obj.ints(end));
					remInt = [remInt, obj.ints(end), interval(2)];
					
					obj.ints = [obj.ints(1:startI-1), interval(2)];

				else
					% Something weird has happened
					error('AI:CantHappen','Finish at end, not odd or even: startI %g, finishI %g', startI, finishI);
				end

			end


			% Starts before all, finishes somewhere else, but not beyond all 
			% This should be replicated in the next big if statment
			% if startI == 1 && ~isnan(finishI) && finishI ~= startI

			% 	% Repair the other cases

			% 	if rem(finishI,2)==1

			% 		% End is outside an interval
			% 		uVAngle = obj.ints(startI) - interval(1);
			% 		remInt = [interval(1), obj.ints(startI)];

			% 		for i = 2:2:finishI-2
						
			% 			uVAngle = uVAngle +  (obj.ints(i+1) - obj.ints(i));
			% 			remInt = [remInt, obj.ints(i), obj.ints(i+1)];
			% 		end

			% 		uVAngle = interval(2) - obj.ints(finishI-1);
			% 		remInt = [obj.ints(finishI-1), interval(2)];
					
			% 		obj.ints = [interval, obj.ints(finishI:end)];

			% 	elseif rem(finishI,2)==0
			% 		% Start is inside an interval

			% 		uVAngle = obj.ints(startI) - interval(1);
			% 		remInt = [interval(1), obj.ints(startI)];

			% 		for i = 2:2:finishI-2
						
			% 			uVAngle = uVAngle +  (obj.ints(i+1) - obj.ints(i));
			% 			remInt = [remInt, obj.ints(i), obj.ints(i+1)];
			% 		end
					
			% 		obj.ints = [interval(1), obj.ints(finishI:end)];

			% 	end

			% end


			% Starts somewhere including in front, finishes somewhere else, but not beyond
			if ~isnan(finishI) && ~isnan(startI) && finishI~=1 && finishI ~= startI % && startI ~= 1

				% If the start is outside an interval but...
				if rem(startI,2)==1

					% ... finish is outside an interval
					if rem(finishI,2)==1

						% End is outside an interval
						uVAngle = obj.ints(startI) - interval(1);
						remInt = [interval(1), obj.ints(startI)];

						for i = startI+1:2:finishI-2
							
							uVAngle = uVAngle +  (obj.ints(i+1) - obj.ints(i));
							remInt = [remInt, obj.ints(i), obj.ints(i+1)];
						end

						uVAngle = uVAngle + (interval(2) - obj.ints(finishI-1));
						remInt = [remInt, obj.ints(finishI-1), interval(2)];
						
						% Special case if startI is before all
						if startI == 1
							obj.ints = [interval, obj.ints(finishI:end)];
						else
							obj.ints = [ obj.ints(1:startI-1), interval, obj.ints(finishI:end)];
						end

					% .. or finish is in an interval
					elseif rem(finishI,2)==0

						uVAngle = obj.ints(startI) - interval(1);
						remInt = [interval(1), obj.ints(startI)];

						for i = startI+1:2:finishI-2
							
							uVAngle = uVAngle +  (obj.ints(i+1) - obj.ints(i));
							remInt = [remInt, obj.ints(i), obj.ints(i+1)];
						end
						
						% Special case if startI is before all
						if startI == 1
							obj.ints = [interval(1), obj.ints(finishI:end)];
						else
							obj.ints = [obj.ints(1:startI-1), interval(1), obj.ints(finishI:end)];
						end

					else
						% Something weird has happened
						error('AI:CantHappen','Start anywhere odd, not odd or even: startI %g, finishI %g', startI, finishI);
					end

				% Start is in an interval ...
				elseif rem(startI,2)==0

					% ... finish is outside an interval
					if rem(finishI,2)==1

						% End is outside an interval
						uVAngle = 0;
						remInt = [];

						for i = startI:2:finishI-2
							
							uVAngle = uVAngle +  (obj.ints(i+1) - obj.ints(i));
							remInt = [remInt, obj.ints(i), obj.ints(i+1)];
						end

						uVAngle = interval(2) - obj.ints(finishI-1);
						remInt = [obj.ints(finishI-1), interval(2)];
						

						obj.ints = [ obj.ints(1:startI-1), interval(2), obj.ints(finishI:end)];

					% .. or finish is in an interval
					elseif rem(finishI,2)==0

						uVAngle = 0;
						remInt = [];

						for i = startI:2:finishI-2
							
							uVAngle = uVAngle +  (obj.ints(i+1) - obj.ints(i));
							remInt = [remInt, obj.ints(i), obj.ints(i+1)];
						end
						

						obj.ints = [obj.ints(1:startI-1), obj.ints(finishI:end)];


					else
						% Something weird has happened
						error('AI:CantHappen','Start anywhere even, not odd or even: startI %g, finishI %g', startI, finishI);
					end

				else
					% Something weird has happened
					error('AI:CantHappen','Start not odd or even: startI %g, finishI %g', startI, finishI);
				end


			end

		end

		function complete = IsCircleComplete(obj)

			% Check to see if the interval is complete

			complete = false;

			if length(obj.ints) == 2 && obj.ints(1) == -obj.PI && obj.ints(2) == obj.PI
				complete = true;
			end

		end

	end

end