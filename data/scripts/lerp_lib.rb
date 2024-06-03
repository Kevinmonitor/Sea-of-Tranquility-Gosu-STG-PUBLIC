def lerp_linear(a, b, x)
	a = a.to_f
	b = b.to_f
	x = x.to_f
	return (a + x * (b - a))
end

def lerp_smooth(a, b, x)
	a = a.to_f
	b = b.to_f
	x = x.to_f
	return (a + x * x * (3 - 2 * x) * (b - a))
end

def lerp_smoother(a, b, x)
	a = a.to_f
	b = b.to_f
	x = x.to_f
	return (a + x * x * x * (x * (x * 6 - 15) + 10) * (b - a))
end

def lerp_accel(a, b, x)
	a = a.to_f
	b = b.to_f
	x = x.to_f
	return (a + x * x * (b - a))
end

def lerp_decel(a, b, x)
	a = a.to_f
	b = b.to_f
	x = x.to_f
    y = 1.0 - x;
    return (a + (1.0 - y * y) * (b - a));
end
