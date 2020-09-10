default: build

clean:
	cabal new-clean

create-keys:
	test -e example/Keys.hs || cp example/Keys.hs.sample example/Keys.hs

build:
	cabal new-build --flag=test

## install ghcid globally: `cabal install ghcid`
watch:
	ghcid --command="cabal new-repl ."

watch-demo:
	ghcid --command="cabal new-repl --flag=test demo-server"

build-demo:
	cabal new-build --flag=test demo-server

repl-demo:
	cabal new-repl --flag=test demo-server

start-demo:
	cabal new-exec --flag=test demo-server

rebuild: clean build

stylish:
	find src example -name '*.hs' | xargs stylish-haskell -i

hlint:
	hlint . --report

doc: build
	cabal new-haddock

dist: rebuild
	cabal new-sdist

## Maybe use hpack?
cabal2nix:
	cabal2nix -ftest . > hoauth2.nix

####################
### CI
####################

ci-build: create-keys
	nix-build

ci-lint:
	nix-shell --command 'make hlint'
