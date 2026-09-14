# FaceAlert

The project is split into separate repositories:

- Frontend: https://github.com/r-el/fa-client
- Backend: https://github.com/r-el/fa-server
- Documentation and repository coordination: https://github.com/r-el/fa

## Clone the complete workspace

Clone the documentation repository together with both repositories:

```bash
git clone --recurse-submodules https://github.com/r-el/fa.git
cd fa
```

If the repository was already cloned without submodules:

```bash
git submodule update --init --recursive
```

## Run locally

Install and run the frontend and backend from their own directories. Each repository also contains its own service-specific README.

```bash
cd server
npm install
npm run dev
```

In a second terminal:

```bash
cd client
npm install
npm run dev
```
