import React from 'react';
import Button from '@material-ui/core/Button';
import TextField from '@material-ui/core/TextField';
import Paper from '@material-ui/core/Paper';
import Container from '@material-ui/core/Container';
import Typography from '@material-ui/core/Typography';

const REST_URL = process.env.REACT_APP_BACKEND_HOST + '/helloworld'

class HelloWorld extends React.Component {

    constructor(props) {
        super(props);
        this.state = {
            savedMessage: undefined,
            message: ""
        }

        this.handleChange = this.handleChange.bind(this);
        this.handleSave = this.handleSave.bind(this);
        this.handlePost = this.handlePost.bind(this);
    }

    handleChange(event) {
        this.setState({ message: event.target.value });
    }

    handleSave(event) {
        event.preventDefault();
        this.submitPost(this.state.message);
    }

    submitPost(message) {
        const body = JSON.stringify({ message: message });
        const promise = fetch(REST_URL, {
            method: "POST",
            body: body,
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
            }
        });

        promise.then(response => {
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            return response.json()
        })
            .then(this.handlePost);
    }

    handlePost(json) {
        this.setState(state => ({
            message: "",
            savedMessage: json.message
        }))
    }

    render() {
        return (
            <Container fixed={true}>
                <Paper>
                    <TextField multiline rows={5} label="Hello World Message" variant="outlined" value={this.state.message} onChange={this.handleChange} />
                    <Button variant="contained" color="primary" onClick={this.handleSave}>Save</Button>
                </Paper>
                <Paper>
                    <Typography variant="body1" gutterBottom>Server hello world - {this.state.savedMessage}</Typography>
                </Paper>
            </Container>
        )
    }
}

export default HelloWorld;