default:
    just --list

deploy:
    pnpm run format
    pnpm run build
    fly deploy --ha=false