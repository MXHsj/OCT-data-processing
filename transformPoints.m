%% apply SE(3) homogenuous transformation T on [u,v,w]
function [x,y,z] = transformPoints(T, u, v, w)

x = zeros(1,length(u));
y = zeros(1,length(u));
z = zeros(1,length(u));
for i = 1:length(u)
    result = T*[u(i), v(i), w(i), 1]';
    x(i) = result(1);
    y(i) = result(2);
    z(i) = result(3);
end
