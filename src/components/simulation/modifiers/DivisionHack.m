classdef DivisionHack < AbstractSimulationModifier
	% In the epithelial layer model, when a cell divides
	% there is a force imbalance that causes a pinching
	% behaviour, that can lead to unintended buckling
	% To prevent the pinching, we control the bottom
	% edges of adjacent cells that have just divided
	% to make sure they stay flat for a period of time
	% after division

	properties

		fadeTime % The length of time to go from full return to no return

	end

	methods

		function obj = DivisionHack(fadeTime)

			obj.fadeTime = fadeTime;

		end

		function ModifySimulation(obj, t)

			% Matlab has some very frustrating quirks, there is no way to
			% use ismember in an && or || statement if one of the vectors could
			% be empty, it throws the error:
			% Operands to the || and && operators must be convertible to logical scalar values.
			% This error appears because when one of the inputs is empty, the output is
 			% 0x0 empty logical array which doesn't seem very sensible to me

			completedList = SquareCellJoined.empty();

			for i = 1:length(t.cellList)
				c = t.cellList(i);

				age = c.GetAge();
				if  age < obj.fadeTime
					if isvalid(c.sisterCell)
						if prod(~ismember(completedList,c.sisterCell))
							% We have a recently divided cell
							% need to move the bottom node it shares
							% with its sister cell to stop the pinching

							% Need to decide which cell is left and right
							if c.nodeBottomLeft == c.sisterCell.nodeBottomRight
								cR = c;
								cL = c.sisterCell;
								sharedNode = c.nodeBottomLeft;
							else
								cR = c.sisterCell;
								cL = c;
								sharedNode = c.nodeBottomRight;
							end

							% Now we need to determine where the shared node should go
							% Need to find a normal vector from the LtoR line and the
							% current node position
							LtoR = cR.nodeBottomRight.position - cL.nodeBottomLeft.position;
							LtoN = sharedNode.position - cL.nodeBottomLeft.position;

							u = LtoR / norm(LtoR);

							% The component of LtoN along u gives the position
							% of the point on LtoR normal to N
							d = dot(u,LtoN); 
							LtoP = d*u; % P is the normal point

							PtoN = LtoN - LtoP;

							% We have a vector going from the normal point to the node
							% now we need to get the fraction of the path based on the age
							% of the cells, and the fadeTime

							proportion = 1; %age/obj.fadeTime;

							newPostion = sharedNode.position - proportion * PtoN;

							% Just need to shift the node now
							t.AdjustNodePosition(sharedNode, newPostion);

							completedList(end + 1) = c;
						end

					end

				end

			end

			
		end

	end

end