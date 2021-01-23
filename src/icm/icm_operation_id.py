class OperationId():

    DEFAULT_NOT_INIT = -1

    def __init__(self, numbers_tuple = None):

        if numbers_tuple is None:
            numbers_tuple = (OperationId.DEFAULT_NOT_INIT, )

        if not isinstance(numbers_tuple, tuple):
            # cast to int
            x = int(numbers_tuple)
            numbers_tuple = (x, )

        self.numbers = tuple(numbers_tuple)

    def add_decomp_level(self):
        # append a zero and return a new ID
        return OperationId(self.numbers + (0,))

    def advance_decomp(self):
        # return
        last_number = self.numbers[-1]
        return OperationId(self.numbers[:-1] + (last_number + 1, ))

    def _cmp_tuple(self):
        return self.numbers

    def __eq__(self, other):
        if not isinstance(other, OperationId):
            return NotImplemented
        return self._cmp_tuple() == other._cmp_tuple()

    def __ne__(self, other):
        if not isinstance(other, OperationId):
            return NotImplemented
        return self._cmp_tuple() != other._cmp_tuple()

    def __lt__(self, other):
        if not isinstance(other, OperationId):
            return NotImplemented
        return self._cmp_tuple() < other._cmp_tuple()

    def __gt__(self, other):
        if not isinstance(other, OperationId):
            return NotImplemented
        return self._cmp_tuple() > other._cmp_tuple()

    def __le__(self, other):
        if not isinstance(other, OperationId):
            return NotImplemented
        return self._cmp_tuple() <= other._cmp_tuple()

    def __ge__(self, other):
        if not isinstance(other, OperationId):
            return NotImplemented
        return self._cmp_tuple() >= other._cmp_tuple()

LEFT_MOST_OP = OperationId((0))
RIGHT_MOST_OP = OperationId((9999999999999999999999))