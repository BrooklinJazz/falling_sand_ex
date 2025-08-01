let Hooks = {}

// Some bullshit is happening because of `this`. God, I work with JavaScript for a tiny little bit and my life is miserable.
Hooks.PixelCanvas = {
    mounted() {
        this.canvas = this.el
        this.ctx = this.canvas.getContext("2d")
        this.cellSize = this.el.getAttribute("cellSize")
        this.shouldWait = false
        this.isMouseDown = false
        this.all_cells = []
        this.x = 0
        this.y = 0
        // Listen for updates from server
        this.handleEvent("render_grid", ({ diffs }) => {
            this.render(diffs)
        })

        this.handleEvent("re-render", ({ all_cells }) => {
            this.reRender(all_cells)
        })

        this.interval = setInterval(() => {
            if (this.isMouseDown) {
                this.pushEvent("set", { x: this.x, y: this.y })
            }
        }, 15)
        this.canvas.addEventListener('mousedown', (event) => {
            this.isMouseDown = true;
            const { x, y } = this.getCanvasCoords(event)
            this.x = x
            this.y = y
        });

        this.canvas.addEventListener('mouseup', () => {
            this.isMouseDown = false;
        });

        this.canvas.addEventListener("mousemove", (event) => {
            if (this.isMouseDown) {
                const { x, y } = this.getCanvasCoords(event)
                this.x = x
                this.y = y
            }
        })
    },

    getCanvasCoords(event) {
        const rect = this.canvas.getBoundingClientRect()
        const scaleX = this.canvas.width / rect.width
        const scaleY = this.canvas.height / rect.height

        const pixelX = (event.clientX - rect.left) * scaleX
        const pixelY = (event.clientY - rect.top) * scaleY

        const x = Math.floor(pixelX / this.cellSize)
        const y = Math.floor(pixelY / this.cellSize)

        return { x, y }
    },

    render(diffs) {
        diffs.forEach(([x, y, element]) => {
            switch (element) {
                case "sand":
                    this.ctx.fillStyle = "orange"
                    this.ctx.fillRect(x * this.cellSize, y * this.cellSize, this.cellSize, this.cellSize)
                    break;
                case "stone":
                    this.ctx.fillStyle = "black"
                    this.ctx.fillRect(x * this.cellSize, y * this.cellSize, this.cellSize, this.cellSize)
                    break;
                case "empty":
                    this.ctx.clearRect(x * this.cellSize, y * this.cellSize, this.cellSize, this.cellSize)
                    break;
                default:
            }
        })
    },
    reRender(all_cells) {
        this.ctx.clearRect(0, 0, this.canvas.height, this.canvas.width)

        all_cells.forEach(([x, y, element]) => {
            switch (element) {
                case "sand":
                    this.ctx.fillStyle = "orange"
                    this.ctx.fillRect(x * this.cellSize, y * this.cellSize, this.cellSize, this.cellSize)
                    break;
                case "stone":
                    this.ctx.fillStyle = "black"
                    this.ctx.fillRect(x * this.cellSize, y * this.cellSize, this.cellSize, this.cellSize)
                    break;
                default:
            }
        })
    }
}

export default Hooks