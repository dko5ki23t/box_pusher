class Point:
    x = 0
    y = 0
    def __init__(self, x: int, y: int):
        self.x = x
        self.y = y

    def __eq__(self, other):
        return self.x == other.x and self.y == other.y

    def __add__(self, other):
        return Point(self.x + other.x, self.y + other.y)
    
    def __sub__(self, other):
        return Point(self.x - other.x, self.y - other.y)
    
    def __mul__(self, other: int):
        return Point(self.x * other, self.x * other)
    
    def copy(self):
        return Point(self.x, self.y)
    
    def distance(self):
        return (abs(self.x) + abs(self.y))
    
class PointRectRange:
    lt = Point(0,0)
    rb = Point(0,0)

    def __init__(self, lt: Point, rb: Point):
        self.lt = lt
        self.rb = rb
        if (lt.x > rb.x or lt.y > rb.y) :
            tmp = lt.copy()
            self.lt = rb.copy()
            self.rb = tmp

    def __eq__(self, other):
        return self.lt == other.lt and self.rb == other.rb

    def contains(self, p: Point):
        return (p.x >= self.lt.x and p.x <= self.rb.x and p.y >= self.lt.y and p.y <= self.rb.y)

    def get_list(self):
        ret = []
        for y in (range(self.lt.y, self.rb.y + 1)):
            for x in (range(self.lt.x, self.rb.x + 1)):
                ret.append(Point(x, y))
                #print(f'({ret[-1].x}, {ret[-1].y})')
        return ret
    
class PointDistanceRange:
    center = Point(0, 0)
    distance = 0

    def __init__(self, center: Point, distance: int):
        self.center = center
        self.distance = distance

    def __eq__(self, other):
        return self.center == other.center and self.distance == other.distance

    def contains(self, p: Point):
        return (p - self.center).distance() <= self.distance

    def get_list(self):
        ret = []
        for dy in (range(-self.distance, self.distance + 1)):
            d2 = self.distance - abs(dy)
            for dx in (range(-d2, d2 + 1)) :
                ret.append(self.center + Point(dx, dy))
        return ret
