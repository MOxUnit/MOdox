function s=str(obj)
% return string representation

    s=sprintf('%s: %s',getReason(obj),str(getLocation(obj)));
