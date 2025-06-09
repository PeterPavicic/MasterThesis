#!/usr/bin/python


class TestClass:
    def __init__(self, asd):
        self.asd = asd
        self.queryText = self.foo()

    def __str__(self):
        return f"This is just some stuff with {self.asd}"

    def foo(self) -> str:
        return f"Foo {self.asd}"



if __name__ == "__main__":
    pass
