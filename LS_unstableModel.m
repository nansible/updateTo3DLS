function [xgrid, zgrid, cgrid, depgrid] = LS_unstableModel(ustar, wstar, L, ...
    z_i, z0, xmin, xmax, zmin, zmax, np, vs, x0, h0, nxgrid, nzgrid, C0)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% LS_UNSTABLEMODEL Simulates particle transport and deposition in an
% unstable atmospheric boundary layer, for all L < 0.
% [xgrid, zgrid, cgrid, depgrid] = LS_unstableModel(ustar, wstar, L, z_i, z0, xmin, 
% xmax, zmin, zmax, np, vs, x0, h0, nxgrid, nzgrid, C0)
%
%   Inputs:
%       ustar   - Friction velocity (m/s)
%       wstar   - Convective velocity scale (m/s)
%       L       - Obukhov length (m)
%       z_i     - Boundary layer height (m)
%       z0      - Roughness length (m)
%       xmin    - Minimum x-coordinate of the domain (m)
%       xmax    - Maximum x-coordinate of the domain (m)
%       zmin    - Minimum z-coordinate of the domain (m)
%       zmax    - Maximum z-coordinate of the domain (m)
%       np      - Number of particles
%       vs      - Particle settling velocity (m/s)
%       x0      - Initial x-coordinate of particles (m)
%       h0      - Initial height of particles (m)
%       nxgrid  - Number of grid cells in the x-direction
%       nzgrid  - Number of grid cells in the z-direction
%       C0      - Lagrangian structure function constant
%
%   Outputs:
%       xgrid   - x-coordinates of the grid (m)
%       zgrid   - z-coordinates of the grid (m)
%       cgrid   - Concentration grid (s/m^3)
%       depgrid - Deposition grid (particles/m)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Make empty arrays and matrices hold particle counts, depositions, residence
% times, and concentration
[xgrid, zgrid, xgridConstant, zgridConstant, pgrid, depgrid, xgridCellSize,...
    zgridCellSize] = LS_makeGrid(xmin, xmax,zmin, zmax, nxgrid, nzgrid);


% Get initial velocity fluctuations for every particle
[up0, wp0] = LS_unstablev0(ustar, wstar, L, z_i, h0, np);

% Release particles in a loop
for p = 1:np  

    % Initialize particle position and velocity
    in_domain = 1;
    x = x0;
    z = h0;
    t = 0;
    up = up0(p);
    wp = wp0(p);

    % Loop to increment particle position while it is still in the domain
    while in_domain

        % Increment the position of the particle
        [x, z, t, dt, up, wp] = LS_unstableStep(ustar, wstar, L, z_i,...
            z0, C0, vs, x, z, t, up, wp);
 
         % If particle leaves domain, mark it as not in domain.
        if x < xmin || x > xmax || z > zmax
            
            % If it leaves the top or sides of domain:
            in_domain = 0;
        
        elseif z < zmin
            
            % Otherwise if it leaves the bottom of the domain ("deposits"), increment
            % depgrid. Also mark it as not in domain.   
            igrid = floor(x/xgridCellSize - xgridConstant);
            depgrid(igrid) = depgrid(igrid) + 1;
            in_domain = 0;
            
        else
        
            % Else, increment pgrid by dt for concentration computation
            igrid = floor(x/xgridCellSize - xgridConstant);
            jgrid = floor(z/zgridCellSize - zgridConstant);
            pgrid(igrid,jgrid) = pgrid(igrid,jgrid)+dt;
        
        end

    end % End of particle position loop
end % End of particle release loop

% Compute concentration from pgrid
cgrid = pgrid/(np*xgridCellSize*zgridCellSize);

end


