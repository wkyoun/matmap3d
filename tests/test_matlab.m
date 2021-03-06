function test_matlab(vendor)
% Test run a scalar self-test of the Matlab/ Octave 3-D coordinate conversion functions

fpath = fileparts(mfilename('fullpath'));
if nargin == 0 || ~vendor
  addpath([fpath,filesep,'..'])
end

if isoctave, warning('off', 'Octave:divide-by-zero'), end

%% reference inputs
az = 33; el=70;
lat = 42; lon= -82;
t0 = datenum(2014,4,6,8,0,0);
%% reference outputs

lat1 = 42.0026; lon1 = -81.9978;

if isoctave
  test_transforms([],lat,lon, lat1, lon1, az, el, 90)
end

test_transforms('d',lat,lon, lat1, lon1, az, el, 90)

test_transforms('r',deg2rad(lat),deg2rad(lon), deg2rad(lat1),deg2rad(lon1), deg2rad(az), deg2rad(el), pi/2)

test_time(t0)

disp('OK: GNU Octave / Matlab code')

end % function

function test_transforms(angleUnit,lat,lon,lat1,lon1,az,el,a90)

alt1 = 1.1397e3; % aer2geodetic
alt = 200; srange = 1e3;
er = 186.277521; nr = 286.84222; ur = 939.69262; % aer2enu
xl = 6.609301927610815e+5; yl = -4.701424222957011e6; zl = 4.246579604632881e+06; % aer2ecef
x0 = 660.6752518e3; y0 = -4700.9486832e3; z0 = 4245.7376622e3; % geodetic2ecef, ecef2geodetic

atol_dist = 1e-3;  % 1 mm

E = wgs84Ellipsoid();
ea = E.SemimajorAxis;
eb = E.SemiminorAxis;

angleUnit=char(angleUnit);

function test_geodetic2ecef()
  [x,y,z] = geodetic2ecef(E,lat,lon,alt, angleUnit);
  assert_allclose([x,y,z],[x0,y0,z0])

  [x,y,z] = geodetic2ecef(lat,lon,alt, angleUnit); % simple input
  assert_allclose([x,y,z],[x0,y0,z0])
  
  [x,y,z] = geodetic2ecef(0,0,-1);
  assert_allclose([x,y,z], [ea-1,0,0])
  
  [x,y,z] = geodetic2ecef(0,90,-1);
  assert_allclose([x,y,z], [0,ea-1,0])
  
  [x,y,z] = geodetic2ecef(0,-90,-1);
  assert_allclose([x,y,z], [0,-ea+1,0])
  
  [x,y,z] = geodetic2ecef(90,0,-1);
  assert_allclose([x,y,z], [0,0,eb-1])
  
  [x,y,z] = geodetic2ecef(90,15,-1);
  assert_allclose([x,y,z], [0,0,eb-1])
  
  [x,y,z] = geodetic2ecef(-90,0,-1);
  assert_allclose([x,y,z], [0,0,-eb+1])
end
test_geodetic2ecef()


function test_ecef2geodetic()
  [lt, ln, at] = ecef2geodetic(E, x0, y0, z0, angleUnit);
  assert_allclose([lt, ln, at], [lat, lon, alt])

  [lt, ln, at] = ecef2geodetic(x0, y0, z0, angleUnit); % simple input
  assert_allclose([lt, ln, at], [lat, lon, alt])

  [lt, ln, at] = ecef2geodetic(ea-1, 0, 0);
  assert_allclose([lt, ln, at], [0, 0, -1])

  [lt, ln, at] = ecef2geodetic(0, ea-1, 0);
  assert_allclose([lt, ln, at], [0, 90, -1])

  [lt, ln, at] = ecef2geodetic(0, 0, eb-1);
  assert_allclose([lt, ln, at], [90, 0, -1])
  
  [lt, ln, at] = ecef2geodetic(0, 0, -eb+1);
  assert_allclose([lt, ln, at], [-90, 0, -1])
  
  [lt, ln, at] = ecef2geodetic(-ea+1, 0, 0);
  assert_allclose([lt, ln, at], [0, 180, -1])
  
  [lt, ln, at] = ecef2geodetic((ea-1000)/sqrt(2), (ea-1000)/sqrt(2), 0);
  assert_allclose([lt,ln,at], [0,45,-1000])
end
test_ecef2geodetic()

function test_enu2aer()
  [a, e, r] = enu2aer(er, nr, ur, angleUnit);
  assert_allclose([a,e,r], [az,el,srange])
  
  [a, e, r] = enu2aer(1, 0, 0, angleUnit);
  assert_allclose([a,e,r], [a90, 0, 1])
  
  [e,n,u] = aer2enu(az, el, srange, angleUnit);
  assert_allclose([e,n,u], [er,nr,ur])
  
  [a,e,r] = enu2aer(e,n,u, angleUnit);
  assert_allclose([a,e,r], [az,el,srange])
end
test_enu2aer()


function test_ecef2aer
  [a, e, r] = ecef2aer(xl,yl,zl, lat,lon,alt, E, angleUnit); % round-trip
  assert_allclose([a,e,r], [az,el,srange])

  % singularity check
  [a, e, r] = ecef2aer(ea-1, 0, 0, 0,0,0, E, angleUnit);
  assert_allclose([a,e,r], [0, -a90, 1])
  
  [a, e, r] = ecef2aer(-ea+1, 0, 0, 0, 2*a90,0, E, angleUnit);
  assert_allclose([a,e,r], [0, -a90, 1])

  [a, e, r] = ecef2aer(0, ea-1, 0,0, a90,0, E, angleUnit);
  assert_allclose([a,e,r], [0, -a90, 1])
  
  [a, e, r] = ecef2aer(0, -ea+1, 0,0, -a90,0, E, angleUnit);
  assert_allclose([a,e,r], [0, -a90, 1])
  
  [a, e, r] = ecef2aer(0, 0, eb-1, a90, 0, 0, E, angleUnit);
  assert_allclose([a,e,r], [0, -a90, 1])
  
  [a, e, r] = ecef2aer(0,  0, -eb+1,-a90,0,0, E, angleUnit);
  assert_allclose([a,e,r], [0, -a90, 1])
  
  [a, e, r] = ecef2aer((ea-1000)/sqrt(2), (ea-1000)/sqrt(2), 0, 0, 45, 0);
  assert_allclose([a,e,r],[0,-90,1000])
  
  [x,y,z] = aer2ecef(az,el,srange,lat,lon,alt,E, angleUnit);
  assert_allclose([x,y,z], [xl,yl,zl])
  
  [a,e,r] = ecef2aer(x,y,z, lat, lon, alt, E, angleUnit);
  assert_allclose([a,e,r], [az,el,srange])
end
test_ecef2aer()

function geodetic_aer()

  [lt,ln,at] = aer2geodetic(az,el,srange,lat,lon,alt, E, angleUnit);
  assert_allclose([lt,ln,at], [lat1, lon1, alt1],[], 2*atol_dist)

  [a, e, r] = geodetic2aer(lt,ln,at,lat,lon,alt, E, angleUnit); % round-trip
  assert_allclose([a,e,r], [az,el,srange])
end
geodetic_aer()
  

function geodetic_enu()
  
  [e, n, u] = geodetic2enu(lat, lon, alt-1, lat, lon, alt, E, angleUnit);
  assert_allclose([e,n,u], [0,0,-1])
  
  [lt, ln, at] = enu2geodetic(e,n,u,lat,lon,alt, E, angleUnit); % round-trip
  assert_allclose([lt, ln, at],[lat, lon, alt-1])

end
geodetic_enu()


function enu_ecef()
  [x, y, z] = enu2ecef(er,nr,ur, lat,lon,alt, E, angleUnit);
  assert_allclose([x,y,z],[xl,yl,zl])
  
  [e,n,u] = ecef2enu(x,y,z,lat,lon,alt, E, angleUnit); % round-trip
  assert_allclose([e,n,u],[er,nr,ur])
end
enu_ecef()

%% 
if strcmp(angleUnit, 'd')
  az5 = [0., 10., 125.];
  tilt = [30, 45, 90];

  [lat5, lon5, rng5] = lookAtSpheroid(lat, lon, alt, az5, 0.);
  assert_allclose(lat5, lat)
  assert_allclose(lon5, lon)
  assert_allclose(rng5, alt)


  [lat5, lon5, rng5] = lookAtSpheroid(lat, lon, alt, az5, tilt);

  truth = [42.00103959, lon, 230.9413173;
           42.00177328, -81.9995808, 282.84715651;
           nan, nan, nan];

  assert_allclose([lat5, lon5, rng5], truth, [], [],true)
end
end % function


function test_time(t0)

assert_allclose(juliantime(t0), 2.45675383333e6)

end


% Copyright (c) 2014-2018 Michael Hirsch, Ph.D.
%
% Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
% 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
% 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
