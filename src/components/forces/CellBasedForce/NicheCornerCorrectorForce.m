classdef NicheCornerCorrectorForce < AbstractCellBasedForce
	% Applies a force to make sure the angle of the cells in
	% the niche of the crypt do not become too extreme
	% It is designed specifically for DynamicCrypt, with SquareCellJoined
	% The corner angles are fixed at pi/4




	properties

		cornerSpringRate
		stroma			% a pointer to the cell acting as a stroma
		nicheRange		% The approximate range above the crypt bottom where we should
						% look for trapezoidal cells. This is probably the only location
						% where there is risk of cells misbehaving, so we avoid applying
						% elsewhere for speed

		preferedAngle = pi/2;

	end

	methods

		function obj = NicheCornerCorrectorForce(cornerP, stroma, nicheRange)

			obj.cornerSpringRate = cornerP;

			obj.stroma = stroma;

			obj.nicheRange = nicheRange;

		end

		function AddCellBasedForces(obj, cellList)

			% For each cell in the list, calculate the forces
			% and add them to the nodes

			% heights = [obj.stroma.nodeList.y];
			% base = sort(heights);
			% base = base(3);

			for i = 1:length(cellList)
				c = cellList(i);
				% centre = c.GetCellCentre;
				% Only add these forces to the epithelial cells if they are in the crypt niche
				if strcmp(class(c), 'SquareCellJoined') %&& centre(2) < base + obj.nicheRange
					if c.DoElementsCross(c.elementLeft, c.elementRight)
						error('Crossing')
					end
					obj.AddCouples(c);
				end

			end

		end

		function AddCouples(obj, c)

			% Each corner has a preferred angle (usually pi/2), and any deviation from that produces a force couple
			% that rotates the elements back towards their preferred angle


			[angleTopLeft, angleBottomRight, angleBottomLeft, angleTopRight] 	= obj.GetCornerAngles(c);

			% The vectors calculated below assume that we are traversing the corners in a clockwise fashion
			[vectorTop, vectorBottom, vectorLeft, vectorRight] 					= obj.GetElementNormalVectors(c);


			% Calculate the torque due to the angle
			% Linear spring
			torqueTopLeft = 	obj.cornerSpringRate * ( obj.preferedAngle - angleTopLeft);
			torqueTopRight = 	obj.cornerSpringRate * ( obj.preferedAngle - angleTopRight);
			torqueBottomLeft = 	obj.cornerSpringRate * ( obj.preferedAngle - angleBottomLeft);
			torqueBottomRight = obj.cornerSpringRate * ( obj.preferedAngle - angleBottomRight);
			% Exponential spring
			% The numbers are specified so that the force starts ramping up after a deviation
			% of pi/6 from the perferred angle, which should be pi/4
			% torqueTopLeft = 	obj.cornerSpringRate * sinh(10 * ( obj.preferedAngle - angleTopLeft)  ) / 500;
			% torqueTopRight = 	obj.cornerSpringRate * sinh(10 * ( obj.preferedAngle - angleTopRight)  ) / 500;
			% torqueBottomLeft = 	obj.cornerSpringRate * sinh(10 * ( obj.preferedAngle - angleBottomLeft)  ) / 500;
			% torqueBottomRight = obj.cornerSpringRate * sinh(10 * ( obj.preferedAngle - angleBottomRight)  ) / 500;

			lenLeft = c.elementLeft.GetLength();
			lenRight = c.elementRight.GetLength();
			lenTop = c.elementTop.GetLength();
			lenBottom = c.elementBottom.GetLength();

			%----------------------------------------------------------------------------------
			% Reordering this to avoid too many calls to AddForceContribution
			blForce = (torqueTopLeft * vectorLeft  /  lenLeft) + (torqueBottomRight * vectorBottom / lenBottom) - (torqueBottomLeft * vectorBottom  / lenBottom) - (torqueBottomLeft * vectorLeft / lenLeft);
			c.nodeBottomLeft.AddForceContribution(blForce);

			tlForce = - (torqueTopLeft * vectorLeft  / lenLeft) - (torqueTopLeft * vectorTop   / lenTop) + (torqueTopRight * vectorTop  / lenTop) + (torqueBottomLeft * vectorLeft / lenLeft);
			c.nodeTopLeft.AddForceContribution(tlForce);

			trForce = (torqueTopLeft * vectorTop   / lenTop) - (torqueTopRight * vectorTop  / lenTop) - (torqueTopRight * vectorRight / lenRight) + (torqueBottomRight * vectorRight  / lenRight);
			c.nodeTopRight.AddForceContribution(trForce);

			brForce = (torqueTopRight * vectorRight / lenRight) - (torqueBottomRight * vectorRight  / lenRight) - (torqueBottomRight * vectorBottom / lenBottom) + (torqueBottomLeft * vectorBottom  / lenBottom);
			c.nodeBottomRight.AddForceContribution(brForce);
			%----------------------------------------------------------------------------------

			% % The following code is replaced by that above which is a bit quicker to run
			% % It is kept here for reference to help understanding where the forces are going 
			% % Forces due to top left angle
			% c.nodeBottomLeft.AddForceContribution(  torqueTopLeft * vectorLeft  /  lenLeft);
			% c.nodeTopLeft.AddForceContribution(    -torqueTopLeft * vectorLeft  / lenLeft );

			% c.nodeTopLeft.AddForceContribution(    -torqueTopLeft * vectorTop   / lenTop );
			% c.nodeTopRight.AddForceContribution(    torqueTopLeft * vectorTop   / lenTop );

			% % Forces due to top right angle
			% c.nodeTopLeft.AddForceContribution(     torqueTopRight * vectorTop  / lenTop );
			% c.nodeTopRight.AddForceContribution(   -torqueTopRight * vectorTop  / lenTop );
			
			% c.nodeTopRight.AddForceContribution(   -torqueTopRight * vectorRight / lenRight );
			% c.nodeBottomRight.AddForceContribution( torqueTopRight * vectorRight / lenRight );

			% % Forces due to bottom right angle
			% c.nodeTopRight.AddForceContribution(    torqueBottomRight * vectorRight  / lenRight );
			% c.nodeBottomRight.AddForceContribution(-torqueBottomRight * vectorRight  / lenRight );
			
			% c.nodeBottomRight.AddForceContribution(-torqueBottomRight * vectorBottom / lenBottom );
			% c.nodeBottomLeft.AddForceContribution(  torqueBottomRight * vectorBottom / lenBottom );

			% % Forces due to bottom left angle
			% c.nodeBottomRight.AddForceContribution( torqueBottomLeft * vectorBottom  / lenBottom );
			% c.nodeBottomLeft.AddForceContribution( -torqueBottomLeft * vectorBottom  / lenBottom );
			
			% c.nodeBottomLeft.AddForceContribution( -torqueBottomLeft * vectorLeft / lenLeft );
			% c.nodeTopLeft.AddForceContribution(     torqueBottomLeft * vectorLeft / lenLeft );




		end


		function [atl, abr, abl, atr] = GetCornerAngles(obj, c)

			% Calculate the angles at each corner
			ntl = c.nodeTopLeft.position;
			ntr = c.nodeTopRight.position;
			nbl = c.nodeBottomLeft.position;
			nbr = c.nodeBottomRight.position;

			atl = acos(  dot(ntr - ntl, nbl - ntl) / ( norm(ntr - ntl) * norm( nbl - ntl) )  );
			atr = acos(  dot(ntl - ntr, nbr - ntr) / ( norm(ntl - ntr) * norm( nbr - ntr) )  );
			abl = acos(  dot(ntl - nbl, nbr - nbl) / ( norm(ntl - nbl) * norm( nbr - nbl) )  );
			abr = acos(  dot(ntr - nbr, nbl - nbr) / ( norm(ntr - nbr) * norm( nbl - nbr) )  );


		end

		function [nvt, nvb, nvl, nvr] = GetElementNormalVectors(obj, c)

			% This returns vectors normal to the element axis that in a force couple will
			% produce anti-clockwise rotation if applied to the starting node

			vt = c.nodeTopRight.position - c.nodeTopLeft.position;
			vr = c.nodeBottomRight.position - c.nodeTopRight.position;
			vl = c.nodeTopLeft.position - c.nodeBottomLeft.position;
			vb = c.nodeBottomLeft.position - c.nodeBottomRight.position;

			nvt = -[vt(2), -vt(1)];
			nvr = -[vr(2), -vr(1)];
			nvl = -[vl(2), -vl(1)];
			nvb = -[vb(2), -vb(1)];
			
			nvt = nvt / norm(nvt);
			nvr = nvr / norm(nvr);
			nvl = nvl / norm(nvl);
			nvb = nvb / norm(nvb);

		end



	end



end