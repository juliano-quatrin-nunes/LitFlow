# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## PPTX rendering (slides export)

The `Slides::PptxRenderer` service shells out to `bin/render_pptx.py`, which
depends on Python 3 and the `python-pptx` library.

On macOS:

```sh
brew install python@3.11
pip3 install python-pptx==1.0.2
```

On Linux (or in CI), use the pinned `requirements.txt` at the repo root:

```sh
python3 -m venv /opt/python
/opt/python/bin/pip install -r requirements.txt
export PATH="/opt/python/bin:$PATH"
```

The production Docker image installs Python and the venv automatically; see the
relevant block in `Dockerfile`.
