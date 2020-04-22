FROM node:12-alpine

RUN apk upgrade && apk add git jq

# The remote where Lerna will push to
WORKDIR /workspaces/remote
RUN git init --bare remote.git

RUN echo "node_modules" >~/.gitignore

# The local repo for our example
WORKDIR /workspaces/dev
RUN     git init \
    &&  git config user.name john \
    &&  git config user.email john@example.com \
    &&  git config --global core.excludesfile ~/.gitignore \
    &&  git remote add origin /workspaces/remote/remote.git \
    &&  git checkout -b integration

# Setup the initial state of our repo
RUN     yarn init -y \
    &&  yarn add lerna --dev \
    &&  npx lerna init --independent \
    &&  npx lerna create lib_a --yes --private \
    &&  npx lerna create lib_b --yes --private \
    &&  npx lerna create lib_c --yes --private \
    &&  jq '.version = "1.0.0-alpha.0"' packages/lib_a/package.json >/tmp/package.json \
    &&  cp /tmp/package.json packages/lib_a/package.json \
    &&  jq '.version = "1.0.0-alpha.0"' packages/lib_b/package.json >/tmp/package.json \
    &&  cp /tmp/package.json packages/lib_b/package.json \
    &&  jq '.version = "1.0.0-alpha.0"' packages/lib_c/package.json >/tmp/package.json \
    &&  cp /tmp/package.json packages/lib_c/package.json \
    &&  npx lerna create website --yes --private --dependencies=lib_a --dependencies=lib_b --dependencies=lib_c \
    &&  jq '.version = "1.0.0-alpha.0"' packages/website/package.json >/tmp/package.json \
    &&  cp /tmp/package.json packages/website/package.json \
    &&  git add . \
    &&  git commit -m "build: setup monorepo with three packages" \
    &&  git push origin integration

CMD ["sh"]
